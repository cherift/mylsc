import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/role.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../providers/shift_providers.dart';

/// Widget formulaire pour affecter un chauffeur à un camion
class DriverAssignmentWidget extends ConsumerStatefulWidget {
  const DriverAssignmentWidget({super.key, this.preselectedTruckId});

  final String? preselectedTruckId;

  @override
  ConsumerState<DriverAssignmentWidget> createState() =>
      _DriverAssignmentWidgetState();
}

class _DriverAssignmentWidgetState
    extends ConsumerState<DriverAssignmentWidget> {
  TruckModel? _selectedTruck;
  UserModel? _selectedDriver;
  bool _isSubmitting = false;
  String? _errorMessage;
  String _driverSearch = '';

  @override
  void initState() {
    super.initState();
    if (widget.preselectedTruckId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadPreselectedTruck();
      });
    }
  }

  Future<void> _loadPreselectedTruck() async {
    final truck =
        await ref.read(truckProvider(widget.preselectedTruckId!).future);
    if (truck != null && mounted) {
      setState(() => _selectedTruck = truck);
    }
  }

  void _resetForm() {
    setState(() {
      _selectedTruck =
          widget.preselectedTruckId != null ? _selectedTruck : null;
      _selectedDriver = null;
      _errorMessage = null;
    });
  }

  Future<void> _submitAssignment() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedTruck == null) {
      setState(
          () => _errorMessage = l10n.translate('assignment.truckRequired'));
      return;
    }

    if (_selectedDriver == null) {
      setState(
          () => _errorMessage = l10n.translate('assignment.driverRequired'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(shiftRepositoryProvider);
      await repository.assignDriver(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        driverId: _selectedDriver!.id,
        driverName: _selectedDriver!.fullName,
        assignedBy: user.id,
        assignedByName: user.fullName,
      );

      ref.invalidate(activeAssignmentsStreamProvider);
      ref.invalidate(
          assignmentsForTruckStreamProvider(_selectedTruck!.id));

      if (mounted) {
        _showSuccessDialog(l10n);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Iconsax.tick_circle,
                color: AppColors.success,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              l10n.translate('assignment.success'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_selectedDriver!.fullName} → ${_selectedTruck!.displayName}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _resetForm();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: const Text(
                'OK',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTruckSelector(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildDriverSelector(l10n),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildErrorBanner(),
          ],
          const SizedBox(height: AppSpacing.xl),
          _buildSubmitButton(l10n),
        ],
      ),
    );
  }

  Widget _buildTruckSelector(AppLocalizations l10n) {
    final trucksAsync = ref.watch(activeTrucksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('assignment.selectTruck'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        trucksAsync.when(
          data: (trucks) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: DropdownButtonFormField<String>(
                initialValue: _selectedTruck?.id,
                hint: Text(
                  l10n.translate('assignment.selectTruckHint'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Iconsax.truck,
                      color: AppColors.primary, size: 24),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                ),
                items: trucks.map((truck) {
                  return DropdownMenuItem(
                    value: truck.id,
                    child: Text(
                      '${truck.immatriculation} - ${truck.marque} ${truck.modele}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (truckId) {
                  if (truckId != null) {
                    final truck =
                        trucks.firstWhere((t) => t.id == truckId);
                    setState(() => _selectedTruck = truck);
                  }
                },
              ),
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child:
                  CircularProgressIndicator(color: AppColors.primary),
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

  Widget _buildDriverSelector(AppLocalizations l10n) {
    final usersAsync = ref.watch(activeUsersProvider);
    // activeAssignmentsStreamProvider couvre les affectations isActive=true
    // (avant ET après le démarrage de la vacation)
    final activeAssignments =
        ref.watch(activeAssignmentsStreamProvider).valueOrNull ?? [];
    final assignedDriverIds =
        activeAssignments.map((a) => a.driverId).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('assignment.selectDriver'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Champ de recherche ──
        TextField(
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: l10n.translate('assignment.searchDriver'),
            hintStyle: const TextStyle(color: AppColors.textTertiary),
            prefixIcon: const Icon(Iconsax.search_normal,
                color: AppColors.textTertiary, size: 20),
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
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          onChanged: (v) => setState(() => _driverSearch = v),
        ),
        const SizedBox(height: AppSpacing.sm),
        // ── Liste filtrée ──
        usersAsync.when(
          data: (users) {
            final query = _driverSearch.toLowerCase().trim();
            final drivers = users
                .where((u) =>
                    u.userRole == UserRole.chauffeur &&
                    !assignedDriverIds.contains(u.id) &&
                    (query.isEmpty ||
                        u.fullName.toLowerCase().contains(query) ||
                        (u.matricule ?? '').toLowerCase().contains(query)))
                .toList();

            if (drivers.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Center(
                  child: Text(
                    l10n.translate('assignment.noDriverAvailable'),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
              );
            }

            return Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: drivers.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: AppColors.surfaceBorder),
                itemBuilder: (context, index) {
                  final driver = drivers[index];
                  final isSelected = _selectedDriver?.id == driver.id;
                  return InkWell(
                    borderRadius: index == 0
                        ? const BorderRadius.vertical(
                            top: Radius.circular(AppRadius.md))
                        : index == drivers.length - 1
                            ? const BorderRadius.vertical(
                                bottom: Radius.circular(AppRadius.md))
                            : BorderRadius.zero,
                    onTap: () => setState(() => _selectedDriver = driver),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : null,
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Iconsax.tick_circle5
                                : Iconsax.user,
                            size: 18,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              driver.fullName,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (driver.matricule != null &&
                              driver.matricule!.isNotEmpty)
                            Text(
                              driver.matricule!,
                              style: const TextStyle(
                                  color: AppColors.textTertiary, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                  );
                },
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
        ),
      ],
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.warning_2, color: AppColors.error),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitAssignment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ),
        child: _isSubmitting
            ? const CircularProgressIndicator(color: Colors.white)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Iconsax.user_add,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.translate('assignment.assign'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
