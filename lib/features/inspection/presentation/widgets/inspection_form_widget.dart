import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Uint8List;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../domain/models/vehicle_inspection_model.dart';
import '../providers/inspection_providers.dart';

/// Widget formulaire pour créer une nouvelle inspection véhicule
class InspectionFormWidget extends ConsumerStatefulWidget {
  const InspectionFormWidget({super.key, this.preselectedTruckId});

  final String? preselectedTruckId;

  @override
  ConsumerState<InspectionFormWidget> createState() =>
      _InspectionFormWidgetState();
}

class _InspectionFormWidgetState extends ConsumerState<InspectionFormWidget> {
  final _observationController = TextEditingController();
  TruckModel? _selectedTruck;
  VehicleState _selectedState = VehicleState.bonEtat;
  final List<XFile> _photos = [];
  final List<Uint8List> _photoBytes = [];
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

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _selectedTruck = widget.preselectedTruckId != null ? _selectedTruck : null;
      _selectedState = VehicleState.bonEtat;
      _observationController.clear();
      _photos.clear();
      _photoBytes.clear();
      _errorMessage = null;
    });
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 80,
    );

    if (image != null && mounted) {
      final bytes = await image.readAsBytes();
      setState(() {
        _photos.add(image);
        _photoBytes.add(bytes);
      });
    }
  }

  Future<void> _submitInspection() async {
    final l10n = AppLocalizations.of(context);

    if (_selectedTruck == null) {
      setState(() => _errorMessage = l10n.translate('inspection.truckRequired'));
      return;
    }

    if (_selectedState == VehicleState.bonEtatAvecObservation &&
        _observationController.text.trim().isEmpty) {
      setState(() =>
          _errorMessage = l10n.translate('inspection.observationRequired'));
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(inspectionRepositoryProvider);
      final displayName = [
        if (user.fullName.isNotEmpty) user.fullName,
        if ((user.matricule ?? '').isNotEmpty) '(${user.matricule})',
      ].join(' ');

      await repository.addInspection(
        truckId: _selectedTruck!.id,
        inspectedBy: user.id,
        inspectedByName: displayName.isNotEmpty ? displayName : null,
        state: _selectedState,
        observation: _observationController.text.trim().isEmpty
            ? null
            : _observationController.text.trim(),
        photos: _photos.isEmpty ? null : _photos,
      );

      ref.invalidate(allInspectionsStreamProvider);
      if (_selectedTruck != null) {
        ref.invalidate(inspectionsStreamProvider(_selectedTruck!.id));
      }

      if (mounted) {
        _showSuccessDialog(l10n);
      }
    } catch (e) {
      if (mounted) {
        setState(() =>
            _errorMessage = '${l10n.translate('inspection.error')}: $e');
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
              l10n.translate('inspection.success'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _selectedTruck!.displayName,
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
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
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
          if (widget.preselectedTruckId == null) ...[
            _buildTruckSelector(l10n),
            const SizedBox(height: AppSpacing.xl),
          ] else if (_selectedTruck != null) ...[
            _buildTruckHeader(_selectedTruck!),
            const SizedBox(height: AppSpacing.xl),
          ],
          _buildStateSelector(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildObservationField(l10n),
          const SizedBox(height: AppSpacing.xl),
          _buildPhotoSection(l10n),
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

  Widget _buildTruckHeader(TruckModel truck) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.truck, color: AppColors.primary, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              truck.displayName,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckSelector(AppLocalizations l10n) {
    final trucksAsync = ref.watch(inspectionAvailableTrucksProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('inspection.selectTruck'),
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
                  l10n.translate('inspection.selectTruckHint'),
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  prefixIcon:
                      Icon(Iconsax.truck, color: AppColors.primary, size: 24),
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
                    final truck = trucks.firstWhere((t) => t.id == truckId);
                    setState(() => _selectedTruck = truck);
                  }
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

  Widget _buildStateSelector(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('inspection.vehicleState'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...VehicleState.values.map((state) {
          final isSelected = _selectedState == state;
          final color = _stateColor(state);
          final icon = _stateIcon(state);
          final label = l10n.translate('inspection.${state.name}');

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () => setState(() => _selectedState = state),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.1)
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color: isSelected ? color : AppColors.surfaceBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: color, size: 24),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 16,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    if (isSelected)
                      Icon(Iconsax.tick_circle, color: color, size: 24),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildObservationField(AppLocalizations l10n) {
    final isRequired =
        _selectedState == VehicleState.bonEtatAvecObservation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              l10n.translate('inspection.observation'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(color: AppColors.error, fontSize: 16),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: TextField(
            controller: _observationController,
            maxLines: 4,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              hintText: l10n.translate('inspection.observationHint'),
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(AppSpacing.md),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.translate('inspection.addPhotos'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_photos.isNotEmpty) ...[
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _photos.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Image.memory(
                        _photoBytes[index],
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _photos.removeAt(index);
                          _photoBytes.removeAt(index);
                        }),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Iconsax.close_circle,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.camera),
                icon: const Icon(Iconsax.camera, size: 20),
                label: Text(l10n.translate('fuel.takePhoto')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPhoto(ImageSource.gallery),
                icon: const Icon(Iconsax.gallery, size: 20),
                label: Text(l10n.translate('common.select')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                ),
              ),
            ),
          ],
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
        onPressed: _isSubmitting ? null : _submitInspection,
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
                  const Icon(Iconsax.tick_circle, color: Colors.white, size: 28),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    l10n.translate('inspection.submit'),
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

  Color _stateColor(VehicleState state) {
    switch (state) {
      case VehicleState.bonEtat:
        return AppColors.success;
      case VehicleState.bonEtatAvecObservation:
        return AppColors.warning;
      case VehicleState.nonFonctionnel:
        return AppColors.error;
      case VehicleState.accidente:
        return AppColors.error;
      case VehicleState.autres:
        return AppColors.textSecondary;
    }
  }

  IconData _stateIcon(VehicleState state) {
    switch (state) {
      case VehicleState.bonEtat:
        return Iconsax.tick_circle;
      case VehicleState.bonEtatAvecObservation:
        return Iconsax.warning_2;
      case VehicleState.nonFonctionnel:
        return Iconsax.close_circle;
      case VehicleState.accidente:
        return Iconsax.danger;
      case VehicleState.autres:
        return Iconsax.info_circle;
    }
  }
}
