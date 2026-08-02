import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../providers/driver_providers.dart';
import '../widgets/create_driver_dialog.dart';
import '../widgets/edit_driver_dialog.dart';
import 'driver_detail_screen.dart';

/// Écran de liste de tous les chauffeurs — pour la Direction/RH
class DriverListScreen extends ConsumerStatefulWidget {
  const DriverListScreen({super.key});

  @override
  ConsumerState<DriverListScreen> createState() => _DriverListScreenState();
}

class _DriverListScreenState extends ConsumerState<DriverListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driversAsync = ref.watch(allDriversProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(child: Column(
        children: [
          _buildHeader(l10n, driversAsync),
          _buildSearchBar(l10n),
          Expanded(
            child: driversAsync.when(
              data: (drivers) {
                final filtered = _searchQuery.isEmpty
                    ? drivers
                    : drivers.where((d) {
                        final q = _searchQuery.toLowerCase();
                        return d.fullName.toLowerCase().contains(q) ||
                            (d.matricule?.toLowerCase().contains(q) ?? false) ||
                            (d.managerName?.toLowerCase().contains(q) ?? false);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Iconsax.driver, size: 48, color: AppColors.textTertiary),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          l10n.translate('driverManagement.noDrivers'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) =>
                      _DriverCard(driver: filtered[index]),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Text('Erreur: $e',
                    style: const TextStyle(color: AppColors.error)),
              ),
            ),
          ),
        ],
      )),
    );
  }

  Widget _buildHeader(
      AppLocalizations l10n, AsyncValue<List<UserModel>> driversAsync) {
    final count = driversAsync.valueOrNull?.length ?? 0;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundSecondary, AppColors.surface],
        ),
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
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
            child: const Icon(Iconsax.driver, color: Colors.white, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.translate('driverManagement.title'),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  l10n.translate('driverManagement.subtitle'),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          if (!context.isMobile)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                '$count ${l10n.translate('driverManagement.driversCount')}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () => showDialog<void>(
              context: context,
              builder: (_) => const CreateDriverDialog(),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Iconsax.user_add, color: Colors.white, size: 18),
            label: Text(
              l10n.translate('driverManagement.createBtn'),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.translate('driverManagement.searchPlaceholder'),
          hintStyle:
              const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon:
              const Icon(Iconsax.search_normal, color: AppColors.textTertiary, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Iconsax.close_circle,
                      color: AppColors.textTertiary, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.surfaceBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
            borderSide: const BorderSide(color: AppColors.primary),
          ),
        ),
        onChanged: (v) => setState(() => _searchQuery = v),
      ),
    );
  }
}

// ── Carte chauffeur ──────────────────────────────────────────────────────────

class _DriverCard extends ConsumerWidget {
  const _DriverCard({required this.driver});

  final UserModel driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final assignmentAsync =
        ref.watch(activeAssignmentStreamForDriverProvider(driver.id));
    final shiftAsync =
        ref.watch(activeShiftStreamForDriverProvider(driver.id));

    final assignment = assignmentAsync.valueOrNull;
    final shift = shiftAsync.valueOrNull;
    final hasActiveShift = shift != null && shift.isOngoing;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.of(context).push<void>(
          MaterialPageRoute<void>(
            builder: (_) => DriverDetailScreen(driver: driver),
          ),
        ),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: hasActiveShift
                  ? AppColors.success.withValues(alpha: 0.4)
                  : AppColors.surfaceBorder,
            ),
          ),
          child: Row(
            children: [
              // Avatar avec photo si disponible, sinon initiales
              _buildAvatar(driver),
              const SizedBox(width: AppSpacing.md),
              // Infos
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            driver.fullName,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Badge vacation
                        _ShiftBadge(hasActive: hasActiveShift, l10n: l10n),
                      ],
                    ),
                    if (driver.matricule != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        driver.matricule!,
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        // Véhicule assigné
                        Expanded(
                          child: _InfoChip(
                            icon: Iconsax.truck,
                            label: assignment?.truckImmatriculation ??
                                l10n.translate('driverManagement.noVehicle'),
                            active: assignment != null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        // Manager
                        Expanded(
                          child: _InfoChip(
                            icon: Iconsax.profile_2user,
                            label: driver.managerName ??
                                l10n.translate('driverManagement.noManager'),
                            active: driver.managerName != null,
                          ),
                        ),
                      ],
                    ),
                    if (hasActiveShift) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _InfoChip(
                        icon: Iconsax.timer_1,
                        label:
                            '${l10n.translate('shift.activeShift')} — ${shift.truckImmatriculation}',
                        active: true,
                        color: AppColors.success,
                      ),
                    ],
                  ],
                ),
              ),
              TextButton.icon(
                icon: const Icon(Iconsax.edit_2,
                    size: 15, color: AppColors.primary),
                label: Text(
                  AppLocalizations.of(context).translate('fleet.editDriver'),
                  style: const TextStyle(
                      color: AppColors.primary, fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => EditDriverDialog(driver: driver),
                ),
              ),
              IconButton(
                icon: const Icon(Iconsax.trash, size: 18,
                    color: AppColors.error),
                tooltip: l10n.translate('driverManagement.deleteDriver'),
                onPressed: () => _confirmDelete(context, ref, driver, l10n),
              ),
              const Icon(Iconsax.arrow_right_3,
                  color: AppColors.textTertiary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref,
      UserModel driver, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          l10n.translate('driverManagement.deleteDriver'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n
              .translate('driverManagement.confirmDeleteDriver')
              .replaceAll('{name}', driver.fullName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              l10n.translate('common.delete'),
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await ref
          .read(userManagementRepositoryProvider)
          .deactivateUser(driver.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('driverManagement.driverDeleted')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Widget _buildAvatar(UserModel driver) {
    final hasPhoto =
        driver.photoUrl != null && driver.photoUrl!.isNotEmpty;
    return CircleAvatar(
      radius: 23,
      backgroundColor: Colors.transparent,
      child: ClipOval(
        child: hasPhoto
            ? Image.network(
                driver.photoUrl!,
                width: 46,
                height: 46,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _initialsAvatar(driver),
              )
            : _initialsAvatar(driver),
      ),
    );
  }

  Widget _initialsAvatar(UserModel driver) {
    return Container(
      width: 46,
      height: 46,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          driver.initials,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.hasActive, required this.l10n});

  final bool hasActive;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final color = hasActive ? AppColors.success : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        hasActive
            ? l10n.translate('shift.active')
            : l10n.translate('driverManagement.inactive'),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.active,
    this.color,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? (active ? AppColors.textSecondary : AppColors.textTertiary);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: c, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
