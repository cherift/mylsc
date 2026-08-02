import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../domain/models/driver_assignment_model.dart';
import '../../domain/models/shift_model.dart';
import '../providers/shift_providers.dart';

/// Widget pour la prise de fonction (démarrer / terminer une vacation)
class ShiftStartWidget extends ConsumerStatefulWidget {
  const ShiftStartWidget({super.key, this.preselectedTruckId, this.fleetId});

  final String? preselectedTruckId;
  final String? fleetId;

  @override
  ConsumerState<ShiftStartWidget> createState() => _ShiftStartWidgetState();
}

class _ShiftStartWidgetState extends ConsumerState<ShiftStartWidget> {
  TruckModel? _selectedTruck;
  DriverAssignmentModel? _selectedAssignment;
  bool _isSubmitting = false;
  String? _errorMessage;

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

  Future<void> _startShift() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedTruck == null) {
      setState(() => _errorMessage = l10n.translate('shift.truckRequired'));
      return;
    }

    if (_selectedAssignment == null) {
      setState(() => _errorMessage = l10n.translate('shift.driverPickerHint'));
      return;
    }

    if (_selectedAssignment!.driverRank != DriverRank.principal) {
      setState(() => _errorMessage = l10n.translate('shift.principalRequired'));
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
      await repository.startShift(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        driverId: _selectedAssignment!.driverId,
        driverName: _selectedAssignment!.driverName,
        startedBy: user.id,
        startedByName: user.fullName,
      );

      ref.invalidate(activeShiftsStreamProvider);
      ref.invalidate(activeShiftForTruckProvider(_selectedTruck!.id));
      ref.invalidate(activeShiftForDriverProvider(_selectedAssignment!.driverId));
      if (widget.fleetId != null) {
        ref.invalidate(shiftsForFleetProvider(widget.fleetId!));
      }

      if (mounted) {
        _showSuccessDialog(l10n, l10n.translate('shift.startSuccess'));
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _endShift(ShiftModel shift) async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          l10n.translate('shift.confirmEnd'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          l10n
              .translate('shift.confirmEndMessage')
              .replaceAll('{driver}', shift.driverName)
              .replaceAll('{truck}', shift.truckImmatriculation),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.translate('shift.no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: Text(
              l10n.translate('shift.yes'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(shiftRepositoryProvider);
      await repository.endShift(
        shift.id,
        driverId: shift.driverId,
        truckId: shift.truckId,
      );

      ref.invalidate(activeShiftsStreamProvider);
      ref.invalidate(activeShiftForTruckProvider(shift.truckId));
      ref.invalidate(activeShiftForDriverProvider(shift.driverId));
      if (widget.fleetId != null) {
        ref.invalidate(shiftsForFleetProvider(widget.fleetId!));
      }

      if (mounted) {
        _showSuccessDialog(l10n, l10n.translate('shift.endSuccess'));
      }
    } catch (e) {
      if (mounted) {
        setState(
            () => _errorMessage = '${l10n.translate('common.error')}: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSuccessDialog(AppLocalizations l10n, String message) {
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
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
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
          if (_selectedTruck != null) ...[
            const SizedBox(height: AppSpacing.xl),
            _buildDriverPicker(l10n),
            const SizedBox(height: AppSpacing.xl),
            _buildActiveShiftInfo(l10n),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            _buildErrorBanner(),
          ],
        ],
      ),
    );
  }

  Widget _buildTruckSelector(AppLocalizations l10n) {
    final trucksAsync = widget.fleetId != null
        ? ref.watch(fleetTrucksProvider(widget.fleetId!))
        : ref.watch(activeTrucksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('shift.selectTruck'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        trucksAsync.when(
          data: (trucks) {
            return InkWell(
              onTap: () async {
                final selected = await showDialog<TruckModel>(
                  context: context,
                  builder: (_) =>
                      _TruckSearchDialog(trucks: trucks, l10n: l10n),
                );
                if (selected != null) {
                  setState(() {
                    _selectedTruck = selected;
                    _selectedAssignment = null;
                    _errorMessage = null;
                  });
                  ref.invalidate(
                      assignmentsForTruckStreamProvider(selected.id));
                  ref.invalidate(
                      activeShiftForTruckProvider(selected.id));
                }
              },
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.truck,
                        color: AppColors.primary, size: 22),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _selectedTruck != null
                          ? Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _selectedTruck!.immatriculation,
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_selectedTruck!
                                        .numeroInterneFlotte
                                        .isNotEmpty)
                                  Text(
                                    '${l10n.translate('trucks.fields.numeroInterne')} : ${_selectedTruck!.numeroInterneFlotte}',
                                    style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            )
                          : Text(
                              l10n.translate('shift.selectTruckHint'),
                              style: const TextStyle(
                                  color: AppColors.textSecondary),
                            ),
                    ),
                    const Icon(Icons.search,
                        color: AppColors.textTertiary, size: 20),
                  ],
                ),
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

  Widget _buildDriverPicker(AppLocalizations l10n) {
    final assignmentsAsync =
        ref.watch(assignmentsForTruckStreamProvider(_selectedTruck!.id));

    return assignmentsAsync.when(
      data: (assignments) {
        if (assignments.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Iconsax.warning_2, color: AppColors.warning, size: 28),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    l10n.translate('shift.noAssignment'),
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.translate('shift.driverPickerTitle'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.translate('shift.driverPickerHint'),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.md),
            ...assignments.map((a) {
              final isPrincipal = a.driverRank == DriverRank.principal;
              final isSelected = _selectedAssignment?.id == a.id;
              final rankColor = switch (a.driverRank) {
                DriverRank.principal => AppColors.primary,
                DriverRank.secondaire => AppColors.info,
                DriverRank.remplacant => AppColors.textSecondary,
              };
              return GestureDetector(
                onTap: isPrincipal
                    ? () => setState(() => _selectedAssignment = a)
                    : null,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.08)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Iconsax.user, color: rankColor, size: 20),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.driverName,
                              style: TextStyle(
                                color: isPrincipal
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 15,
                                fontWeight: isPrincipal
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                              ),
                            ),
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(
                                color: rankColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                l10n.translate(a.driverRank.i18nKey),
                                style: TextStyle(
                                    color: rankColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isPrincipal)
                        Tooltip(
                          message: l10n.translate('shift.principalRequired'),
                          child: const Icon(Iconsax.lock,
                              color: AppColors.textTertiary, size: 18),
                        )
                      else if (isSelected)
                        const Icon(Iconsax.tick_circle,
                            color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              );
            }),
          ],
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

  Widget _buildActiveShiftInfo(AppLocalizations l10n) {
    final shiftAsync =
        ref.watch(activeShiftForTruckProvider(_selectedTruck!.id));

    return shiftAsync.when(
      data: (shift) {
        if (shift != null) {
          return _buildActiveShiftCard(l10n, shift);
        }
        return _buildStartShiftButton(l10n);
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

  Widget _buildActiveShiftCard(AppLocalizations l10n, ShiftModel shift) {
    final duration = shift.duration;
    final hours = duration != null ? duration.inHours : 0;
    final minutes = duration != null ? duration.inMinutes % 60 : 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border:
            Border.all(color: AppColors.success.withValues(alpha: 0.3)),
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
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Iconsax.user, color: AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                shift.driverName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              const Icon(Iconsax.clock, color: AppColors.textSecondary,
                  size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.translate('shift.shiftSince')} ${_formatTime(shift.startTime)} (${hours}h${minutes.toString().padLeft(2, '0')})',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : () => _endShift(shift),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
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
                        const Icon(Iconsax.stop,
                            color: Colors.white, size: 24),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          l10n.translate('shift.endShift'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartShiftButton(AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _startShift,
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
                  const Icon(Iconsax.play,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.translate('shift.startShift'),
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

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

// ── Dialog de recherche de véhicule ──────────────────────────────────────────

class _TruckSearchDialog extends StatefulWidget {
  const _TruckSearchDialog({required this.trucks, required this.l10n});

  final List<TruckModel> trucks;
  final AppLocalizations l10n;

  @override
  State<_TruckSearchDialog> createState() => _TruckSearchDialogState();
}

class _TruckSearchDialogState extends State<_TruckSearchDialog> {
  final _searchController = TextEditingController();
  late List<TruckModel> _filtered;

  @override
  void initState() {
    super.initState();
    _filtered = widget.trucks;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = query.toLowerCase().trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.trucks
          : widget.trucks.where((t) {
              return t.immatriculation.toLowerCase().contains(q) ||
                  t.numeroInterneFlotte.toLowerCase().contains(q);
            }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      title: Text(
        l10n.translate('shift.selectTruck'),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
      content: SizedBox(
        width: 420,
        height: 420,
        child: Column(
          children: [
            // Champ de recherche
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: l10n.translate('trucks.searchHint'),
                hintStyle:
                    const TextStyle(color: AppColors.textTertiary),
                prefixIcon: const Icon(Icons.search,
                    color: AppColors.textTertiary),
                filled: true,
                fillColor: AppColors.backgroundSecondary,
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
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              ),
              onChanged: _filter,
            ),
            const SizedBox(height: AppSpacing.md),
            // Liste filtrée
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text(
                        l10n.translate('trucks.noTrucksFound'),
                        style: const TextStyle(
                            color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: AppColors.surfaceBorder),
                      itemBuilder: (context, index) {
                        final truck = _filtered[index];
                        return ListTile(
                          leading: const Icon(Iconsax.truck,
                              color: AppColors.primary, size: 22),
                          title: Text(
                            truck.immatriculation,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: truck
                                  .numeroInterneFlotte.isNotEmpty
                              ? Text(
                                  '${l10n.translate('trucks.fields.numeroInterne')} : ${truck.numeroInterneFlotte}',
                                  style: const TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12),
                                )
                              : null,
                          trailing: Text(
                            '${truck.marque} ${truck.modele}',
                            style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12),
                          ),
                          onTap: () => Navigator.of(context).pop(truck),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.translate('common.cancel')),
        ),
      ],
    );
  }
}
