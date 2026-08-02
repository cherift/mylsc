import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../providers/fuel_request_providers.dart';

/// Widget formulaire pour créer une demande de carburant
class FuelRequestFormWidget extends ConsumerStatefulWidget {
  const FuelRequestFormWidget({super.key, this.preselectedTruckId});

  final String? preselectedTruckId;

  @override
  ConsumerState<FuelRequestFormWidget> createState() =>
      _FuelRequestFormWidgetState();
}

class _FuelRequestFormWidgetState
    extends ConsumerState<FuelRequestFormWidget> {
  TruckModel? _selectedTruck;
  final _litersController = TextEditingController();
  final _reasonController = TextEditingController();
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

  @override
  void dispose() {
    _litersController.dispose();
    _reasonController.dispose();
    super.dispose();
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
      _litersController.clear();
      _reasonController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _submitRequest() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedTruck == null) {
      setState(
          () => _errorMessage = l10n.translate('fuelRequest.truckRequired'));
      return;
    }

    final litersText = _litersController.text.trim();
    if (litersText.isEmpty) {
      setState(
          () => _errorMessage = l10n.translate('fuelRequest.litersRequired'));
      return;
    }

    final liters = double.tryParse(litersText);
    if (liters == null || liters <= 0) {
      setState(
          () => _errorMessage = l10n.translate('fuelRequest.litersInvalid'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(fuelRequestRepositoryProvider);
      final activeShift = await ref
          .read(shiftRepositoryProvider)
          .getActiveShiftForTruck(_selectedTruck!.id);
      await repository.createRequest(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        truckFleetNumber: _selectedTruck!.numeroInterneFlotte,
        requestedBy: user.id,
        requestedByName: user.fullName,
        requestedLiters: liters,
        driverId: activeShift?.driverId,
        driverName: activeShift?.driverName,
        reason: _reasonController.text.trim().isNotEmpty
            ? _reasonController.text.trim()
            : null,
      );

      ref.invalidate(pendingRequestsStreamProvider);
      ref.invalidate(userRequestsStreamProvider(user.id));

      if (mounted) {
        _showSuccessDialog(l10n);
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
              l10n.translate('fuelRequest.success'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_litersController.text}L → ${_selectedTruck!.immatriculation}',
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
          _buildLitersField(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildReasonField(l10n),
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
          l10n.translate('fuelRequest.selectTruck'),
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
                  l10n.translate('fuelRequest.selectTruckHint'),
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
                    setState(() {
                      _selectedTruck = truck;
                      _errorMessage = null;
                    });
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

  Widget _buildLitersField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('fuelRequest.liters'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: _litersController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
            ],
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
            ),
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.gas_station,
                  color: AppColors.primary, size: 24),
              hintText: l10n.translate('fuelRequest.litersHint'),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              suffixText: 'L',
              suffixStyle: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReasonField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('fuelRequest.reason'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: _reasonController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 48),
                child: Icon(Iconsax.document_text,
                    color: AppColors.primary, size: 24),
              ),
              hintText: l10n.translate('fuelRequest.reasonHint'),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
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
        onPressed: _isSubmitting ? null : _submitRequest,
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
                  const Icon(Iconsax.send_1,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.translate('fuelRequest.submit'),
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
