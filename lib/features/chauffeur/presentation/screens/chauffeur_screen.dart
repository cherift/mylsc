import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../shifts/domain/models/shift_model.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../trips/domain/models/trip_model.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../../../breakdown/presentation/widgets/breakdown_form_widget.dart';
import '../../../breakdown/presentation/widgets/breakdown_alert_widget.dart';

/// Écran principal du chauffeur
class ChauffeurScreen extends ConsumerStatefulWidget {
  const ChauffeurScreen({super.key});

  @override
  ConsumerState<ChauffeurScreen> createState() => _ChauffeurScreenState();
}

class _ChauffeurScreenState extends ConsumerState<ChauffeurScreen> {
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
                  child: _buildTabContent(l10n, user),
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
              Iconsax.driver,
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
                  user.fullName.isEmpty ? user.email : user.fullName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.translate('users.roles.chauffeur'),
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
            tooltip: l10n.translate('settings.title'),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).signOut();
              if (mounted) {
                await Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            icon: const Icon(Iconsax.logout, color: AppColors.error),
            tooltip: l10n.translate('auth.logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(AppLocalizations l10n, UserModel user) {
    switch (_currentTab) {
      case 0:
        return _buildHomeTab(l10n, user);
      case 1:
        return _buildAssignmentsTab(l10n, user);
      case 2:
        return _buildTripsTab(l10n, user);
      case 3:
        return const BreakdownFormWidget();
      default:
        return _buildHomeTab(l10n, user);
    }
  }

  Widget _buildHomeTab(AppLocalizations l10n, UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildActiveShiftCard(l10n, user),
          const SizedBox(height: AppSpacing.lg),
          const BreakdownAlertWidget(),
          const SizedBox(height: AppSpacing.lg),
          _buildRecentTripsSection(l10n, user),
        ],
      ),
    );
  }

  Widget _buildActiveShiftCard(AppLocalizations l10n, UserModel user) {
    final shiftAsync = ref.watch(activeShiftForDriverProvider(user.id));

    return shiftAsync.when(
      data: (shift) {
        if (shift == null) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: const Icon(Iconsax.clock,
                      color: AppColors.textSecondary, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.translate('shift.noAssignment'),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final duration = shift.duration;
        final hours = duration?.inHours ?? 0;
        final minutes = (duration?.inMinutes ?? 0) % 60;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
                color: AppColors.success.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.translate('shift.activeShift'),
                    style: const TextStyle(
                      color: AppColors.success,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Icon(Iconsax.truck,
                      color: AppColors.textPrimary, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      shift.truckImmatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(Iconsax.clock,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      '${l10n.translate('shift.shiftSince')} ${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')} (${hours}h${minutes.toString().padLeft(2, '0')})',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      ),
      error: (error, _) => Text(
        '${l10n.translate('common.error')}: $error',
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }

  Widget _buildRecentTripsSection(AppLocalizations l10n, UserModel user) {
    final tripsAsync = ref.watch(driverTripsStreamProvider(user.id));

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
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            }

            final recent = trips.take(5).toList();
            return Column(
              children: recent
                  .map((trip) => _buildTripCard(l10n, trip))
                  .toList(),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (error, _) => Text(
            '${l10n.translate('common.error')}: $error',
            style: const TextStyle(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildAssignmentsTab(AppLocalizations l10n, UserModel user) {
    final shiftsAsync = ref.watch(shiftsForDriverStreamProvider(user.id));

    return shiftsAsync.when(
      data: (shifts) {
        if (shifts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.calendar_1,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('shift.noAssignment'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        final endedShifts =
            shifts.where((s) => s.endTime != null).toList();
        final totalWork = endedShifts.fold<Duration>(
            Duration.zero, (acc, s) => acc + (s.duration ?? Duration.zero));
        final avgWork = endedShifts.isNotEmpty
            ? Duration(minutes: totalWork.inMinutes ~/ endedShifts.length)
            : Duration.zero;

        String fmtD(Duration d) =>
            '${d.inHours}h${(d.inMinutes % 60).toString().padLeft(2, '0')}';

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, 0),
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border:
                    Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildWorkStat(
                      Iconsax.timer_1,
                      l10n.translate('shift.totalWorkTime'),
                      fmtD(totalWork),
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildWorkStat(
                      Iconsax.clock,
                      l10n.translate('shift.averageDuration'),
                      endedShifts.isNotEmpty ? fmtD(avgWork) : '-',
                      AppColors.info,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildWorkStat(
                      Iconsax.calendar_tick,
                      l10n.translate('shift.completedShifts'),
                      '${endedShifts.length}/${shifts.length}',
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: shifts.length,
                itemBuilder: (context, index) =>
                    _buildShiftCard(l10n, shifts[index]),
              ),
            ),
          ],
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

  Widget _buildWorkStat(
      IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
              color: color, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style:
              const TextStyle(color: AppColors.textSecondary, fontSize: 10),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildShiftCard(AppLocalizations l10n, ShiftModel shift) {
    final isActive = shift.status == ShiftStatus.active;
    final statusColor = isActive ? AppColors.success : AppColors.textSecondary;
    final duration = shift.duration;
    final hours = duration?.inHours ?? 0;
    final minutes = (duration?.inMinutes ?? 0) % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isActive
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.surfaceBorder,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              isActive ? Iconsax.truck_fast : Iconsax.truck_tick,
              color: statusColor,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift.truckImmatriculation,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${shift.startTime.day.toString().padLeft(2, '0')}/${shift.startTime.month.toString().padLeft(2, '0')}/${shift.startTime.year} - ${shift.startTime.hour.toString().padLeft(2, '0')}:${shift.startTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (!isActive && shift.endTime != null)
                  Text(
                    '${l10n.translate('shift.duration')}: ${hours}h${minutes.toString().padLeft(2, '0')}',
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
              isActive
                  ? l10n.translate('shift.active')
                  : l10n.translate('shift.ended'),
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
  }

  Widget _buildTripsTab(AppLocalizations l10n, UserModel user) {
    final tripsAsync = ref.watch(driverTripsStreamProvider(user.id));

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
                    color: AppColors.textSecondary,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: trips.length,
          itemBuilder: (context, index) =>
              _buildTripCard(l10n, trips[index]),
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

  Widget _buildTripCard(AppLocalizations l10n, TripModel trip) {
    final statusColor = _getTripStatusColor(trip.status);
    final statusLabel = _getTripStatusLabel(l10n, trip.status);

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
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(Iconsax.repeat, color: statusColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.truckImmatriculation,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  trip.formattedDate,
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
              statusLabel,
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
          icon: const Icon(Iconsax.home),
          label: l10n.translate('dashboard.home'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.calendar_1),
          label: l10n.translate('chauffeur.assignments'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.repeat),
          label: l10n.translate('trip.title'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Iconsax.warning_2),
          label: l10n.translate('breakdown.reportBreakdown'),
        ),
      ],
    );
  }
}
