import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../domain/models/breakdown_report_model.dart';
import '../providers/breakdown_providers.dart';

/// Widget formulaire pour signaler une panne
class BreakdownFormWidget extends ConsumerStatefulWidget {
  const BreakdownFormWidget({super.key, this.preselectedTruckId});

  final String? preselectedTruckId;

  @override
  ConsumerState<BreakdownFormWidget> createState() =>
      _BreakdownFormWidgetState();
}

class _BreakdownFormWidgetState extends ConsumerState<BreakdownFormWidget> {
  TruckModel? _selectedTruck;
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  BreakdownSeverity _severity = BreakdownSeverity.medium;
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
    _descriptionController.dispose();
    _locationController.dispose();
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
      _descriptionController.clear();
      _locationController.clear();
      _severity = BreakdownSeverity.medium;
      _errorMessage = null;
    });
  }

  Future<void> _submitBreakdown() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedTruck == null) {
      setState(
          () => _errorMessage = l10n.translate('breakdown.truckRequired'));
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = l10n.translate('breakdown.descriptionRequired'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(breakdownRepositoryProvider);
      await repository.createBreakdown(
        truckId: _selectedTruck!.id,
        truckImmatriculation: _selectedTruck!.immatriculation,
        truckFleetNumber: _selectedTruck!.numeroInterneFlotte,
        reportedBy: user.id,
        reportedByName: user.fullName,
        description: _descriptionController.text.trim(),
        severity: _severity,
        location: _locationController.text.trim().isNotEmpty
            ? _locationController.text.trim()
            : null,
      );

      ref.invalidate(pendingBreakdownsStreamProvider);
      ref.invalidate(activeBreakdownsStreamProvider);

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
              l10n.translate('breakdown.success'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedTruck!.immatriculation,
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
          _buildSeveritySelector(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildDescriptionField(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildLocationField(l10n),
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
          l10n.translate('breakdown.selectTruck'),
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
                  l10n.translate('breakdown.selectTruckHint'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon: Icon(Iconsax.truck,
                      color: AppColors.error, size: 24),
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

  Widget _buildSeveritySelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('breakdown.severity'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: BreakdownSeverity.values.map((severity) {
            final isSelected = _severity == severity;
            final color = _getSeverityColor(severity);
            final label = _getSeverityLabel(l10n, severity);

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _severity = severity),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? color.withValues(alpha: 0.15)
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    border: Border.all(
                      color: isSelected ? color : AppColors.surfaceBorder,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _getSeverityIcon(severity),
                        color: isSelected ? color : AppColors.textSecondary,
                        size: 24,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? color
                              : AppColors.textSecondary,
                          fontSize: 12,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('breakdown.description'),
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
            controller: _descriptionController,
            maxLines: 4,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Padding(
                padding: EdgeInsets.only(bottom: 72),
                child: Icon(Iconsax.document_text,
                    color: AppColors.error, size: 24),
              ),
              hintText: l10n.translate('breakdown.descriptionHint'),
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

  Widget _buildLocationField(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('breakdown.location'),
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
            controller: _locationController,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              prefixIcon: const Icon(Iconsax.location,
                  color: AppColors.primary, size: 24),
              hintText: l10n.translate('breakdown.locationHint'),
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
        onPressed: _isSubmitting ? null : _submitBreakdown,
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
                  const Icon(Iconsax.warning_2,
                      color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.translate('breakdown.submit'),
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

  Color _getSeverityColor(BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return AppColors.info;
      case BreakdownSeverity.medium:
        return AppColors.warning;
      case BreakdownSeverity.high:
        return AppColors.error;
      case BreakdownSeverity.critical:
        return const Color(0xFFB71C1C);
    }
  }

  IconData _getSeverityIcon(BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return Iconsax.info_circle;
      case BreakdownSeverity.medium:
        return Iconsax.warning_2;
      case BreakdownSeverity.high:
        return Iconsax.danger;
      case BreakdownSeverity.critical:
        return Iconsax.flash_1;
    }
  }

  String _getSeverityLabel(AppLocalizations l10n, BreakdownSeverity severity) {
    switch (severity) {
      case BreakdownSeverity.low:
        return l10n.translate('breakdown.severityLow');
      case BreakdownSeverity.medium:
        return l10n.translate('breakdown.severityMedium');
      case BreakdownSeverity.high:
        return l10n.translate('breakdown.severityHigh');
      case BreakdownSeverity.critical:
        return l10n.translate('breakdown.severityCritical');
    }
  }
}
