import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../settings/presentation/screens/settings_screen.dart';
import '../../domain/models/fuel_request_model.dart';
import '../providers/fuel_providers.dart';
import '../providers/fuel_request_providers.dart';
import '../widgets/fuel_request_detail_sheet.dart';

/// Écran simplifié pour le pompiste - Interface ultra-simple
class FuelAttendantScreen extends ConsumerStatefulWidget {
  const FuelAttendantScreen({super.key});

  @override
  ConsumerState<FuelAttendantScreen> createState() => _FuelAttendantScreenState();
}

class _FuelAttendantScreenState extends ConsumerState<FuelAttendantScreen> {
  final _immatriculationController = TextEditingController();
  final _verificationCodeController = TextEditingController();
  final _litersController = TextEditingController();
  final _receiptNumberController = TextEditingController();
  final _observationController = TextEditingController();

  FuelRequestModel? _validatedRequest;
  XFile? _receiptPhoto;
  Uint8List? _receiptPhotoBytes;
  bool _isSearching = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  bool _showSettings = false;
  int _currentTab = 0;

  @override
  void dispose() {
    _immatriculationController.dispose();
    _verificationCodeController.dispose();
    _litersController.dispose();
    _receiptNumberController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _immatriculationController.clear();
      _verificationCodeController.clear();
      _litersController.clear();
      _receiptNumberController.clear();
      _observationController.clear();
      _validatedRequest = null;
      _receiptPhoto = null;
      _receiptPhotoBytes = null;
      _errorMessage = null;
    });
  }

  Future<void> _searchRequest() async {
    final l10n = AppLocalizations.of(context);
    if (_immatriculationController.text.isEmpty ||
        _verificationCodeController.text.isEmpty) {
      setState(() {
        _errorMessage = l10n.translate('fuel.fillBothFields');
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(fuelRequestRepositoryProvider);

      // 1. Chercher une demande en attente (servable par le pompiste)
      final pendingRequest =
          await repository.findApprovedRequestByImmatriculationAndCode(
        immatriculation: _immatriculationController.text.trim(),
        verificationCode: _verificationCodeController.text.trim(),
      );

      if (pendingRequest != null) {
        setState(() {
          _validatedRequest = pendingRequest;
          _isSearching = false;
        });
        return;
      }

      // 2. Si non trouvée comme pending, chercher sans filtre statut
      //    pour donner un message d'erreur précis
      final anyRequest =
          await repository.findRequestByImmatriculationAndCode(
        immatriculation: _immatriculationController.text.trim(),
        verificationCode: _verificationCodeController.text.trim(),
      );

      String errorMsg;
      if (anyRequest == null) {
        errorMsg = l10n.translate('fuel.requestNotFound');
      } else if (anyRequest.status == FuelRequestStatus.cancelled) {
        errorMsg = l10n.translate('fuel.requestCancelled');
      } else if (anyRequest.status == FuelRequestStatus.fulfilled ||
          anyRequest.status == FuelRequestStatus.validated) {
        errorMsg = l10n.translate('fuel.requestAlreadyServed');
      } else if (anyRequest.status == FuelRequestStatus.rejected) {
        errorMsg = l10n.translate('fuel.requestRejected');
      } else {
        errorMsg = l10n.translate('fuel.requestNotFound');
      }

      setState(() {
        _validatedRequest = null;
        _isSearching = false;
        _errorMessage = errorMsg;
      });
    } catch (e) {
      setState(() {
        _isSearching = false;
        _errorMessage = '${l10n.translate('common.error')}: $e';
      });
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final l10n = AppLocalizations.of(context);
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        if (mounted) {
          setState(() {
            _receiptPhoto = image;
            _receiptPhotoBytes = bytes;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '${l10n.translate('common.error')}: $e';
        });
      }
    }
  }

  // Caméra indisponible sur de nombreux postes web (pas de webcam,
  // permission refusée...) — on propose toujours aussi la galerie/import
  // de fichier, qui fonctionne partout.
  Future<void> _showPhotoSourceSheet() async {
    final l10n = AppLocalizations.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.camera, color: AppColors.primary),
              title: Text(l10n.translate('photos.camera')),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.gallery, color: AppColors.primary),
              title: Text(l10n.translate('photos.gallery')),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Future<void> _submitFuelEntry() async {
    final l10n = AppLocalizations.of(context);
    if (_validatedRequest == null) return;
    if (_litersController.text.isEmpty) {
      setState(() {
        _errorMessage = l10n.translate('fuel.litersRequired');
      });
      return;
    }

    final liters = double.tryParse(_litersController.text.replaceAll(',', '.'));
    if (liters == null || liters <= 0) {
      setState(() {
        _errorMessage = l10n.translate('fuel.litersRequired');
      });
      return;
    }

    if (_receiptNumberController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = l10n.translate('fuel.receiptNumberRequired');
      });
      return;
    }

    if (_receiptPhoto == null) {
      setState(() {
        _errorMessage = l10n.translate('fuel.photoRequired');
      });
      return;
    }

    final user = ref.read(authControllerProvider).value;
    if (user == null) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(fuelRepositoryProvider);
      final entry = await repository.addFuelEntry(
        truckId: _validatedRequest!.truckId,
        truckImmatriculation: _validatedRequest!.truckImmatriculation,
        truckFleetNumber: _validatedRequest!.truckFleetNumber ?? '',
        liters: liters,
        addedBy: user.id,
        addedByName: user.fullName.isEmpty ? user.email : user.fullName,
        receiptPhoto: _receiptPhoto,
      );

      // Mark request as fulfilled
      final requestRepo = ref.read(fuelRequestRepositoryProvider);
      await requestRepo.fulfillRequest(
        requestId: _validatedRequest!.id,
        fulfilledBy: user.id,
        fulfilledByName: user.fullName.isEmpty ? user.email : user.fullName,
        fulfilledLiters: liters,
        fuelEntryId: entry.id,
        receiptPhotoUrl: entry.receiptPhotoUrl,
        receiptNumber: _receiptNumberController.text.trim(),
        observation: _observationController.text.trim().isNotEmpty
            ? _observationController.text.trim()
            : null,
      );

      final isAutoValidated = liters == _validatedRequest!.requestedLiters;

      if (mounted) {
        _showSuccessDialog(isAutoValidated: isAutoValidated);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog({required bool isAutoValidated}) {
    final l10n = AppLocalizations.of(context);
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
              l10n.translate('fuel.success'),
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${_litersController.text} L - ${_validatedRequest!.truckImmatriculation}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isAutoValidated
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isAutoValidated ? Iconsax.tick_circle : Iconsax.timer,
                    color: isAutoValidated ? AppColors.success : AppColors.warning,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    isAutoValidated
                        ? l10n.translate('fuel.autoValidated')
                        : l10n.translate('fuel.pendingValidation'),
                    style: TextStyle(
                      color: isAutoValidated ? AppColors.success : AppColors.warning,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
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
                icon: const Icon(Iconsax.arrow_left, color: AppColors.textPrimary),
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
                  child: _currentTab == 0
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: _validatedRequest == null
                              ? _buildSearchSection(l10n)
                              : _buildFuelEntrySection(l10n),
                        )
                      : _buildActivitiesList(l10n, user),
                ),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentTab,
            onTap: (index) => setState(() => _currentTab = index),
            backgroundColor: AppColors.backgroundSecondary,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: AppColors.textSecondary,
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Iconsax.gas_station),
                label: l10n.translate('fuel.newEntry'),
              ),
              BottomNavigationBarItem(
                icon: const Icon(Iconsax.activity),
                label: l10n.translate('fuel.activities'),
              ),
            ],
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
          child: Text('Erreur: $error', style: const TextStyle(color: AppColors.error)),
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
              Iconsax.gas_station,
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
                  l10n.translate('dashboard.appName'),
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
            icon: const Icon(Iconsax.setting_2, color: AppColors.textSecondary),
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
            tooltip: l10n.authLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchSection(AppLocalizations l10n) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.xl),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Iconsax.gas_station,
            color: AppColors.primary,
            size: 48,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          l10n.translate('fuel.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.xl),
        _buildTextField(
          controller: _immatriculationController,
          label: l10n.translate('fuel.enterImmatriculation'),
          icon: Iconsax.car,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildTextField(
          controller: _verificationCodeController,
          label: l10n.translate('fuel.enterVerificationCode'),
          icon: Iconsax.shield_tick,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
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
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        SizedBox(
          width: double.infinity,
          height: 64,
          child: ElevatedButton(
            onPressed: _isSearching ? null : _searchRequest,
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
            child: _isSearching
                ? const CircularProgressIndicator(color: Colors.white)
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Iconsax.search_normal, color: Colors.white, size: 28),
                        const SizedBox(width: AppSpacing.md),
                        Text(
                          l10n.translate('fuel.validateVehicle'),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFuelEntrySection(AppLocalizations l10n) {
    return Column(
      children: [
        // Véhicule validé
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.success),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: const Icon(Iconsax.tick_circle, color: Colors.white),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.translate('fuel.vehicleFound'),
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          _validatedRequest!.truckImmatriculation,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _validatedRequest = null),
                    icon: const Icon(Iconsax.close_circle, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      icon: Iconsax.car,
                      label: _validatedRequest!.truckImmatriculation,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildInfoChip(
                      icon: Iconsax.shield_tick,
                      label: 'Code: ${_validatedRequest!.verificationCode ?? ''}',
                    ),
                  ),
                ],
              ),
              if (_validatedRequest!.requestedByName.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                _buildInfoChip(
                  icon: Iconsax.user,
                  label: _validatedRequest!.requestedByName,
                ),
              ],
              const SizedBox(height: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.primary),
                ),
                child: Row(
                  children: [
                    const Icon(Iconsax.drop, color: AppColors.primary, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        '${l10n.translate('fuel.requestedQuantity')}: ${_validatedRequest!.requestedLiters.toStringAsFixed(1)} L',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        // Saisie des litres
        _buildTextField(
          controller: _litersController,
          label: l10n.translate('fuel.enterLiters'),
          icon: Iconsax.drop,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[\d.,]')),
          ],
          fontSize: 32,
          suffix: 'L',
        ),
        const SizedBox(height: AppSpacing.md),
        // Numéro de reçu (obligatoire)
        _buildTextField(
          controller: _receiptNumberController,
          label: '${l10n.translate('fuel.receiptNumber')} *',
          icon: Iconsax.receipt_2,
        ),
        const SizedBox(height: AppSpacing.md),
        // Observation (facultative)
        _buildTextField(
          controller: _observationController,
          label: l10n.translate('fuel.observation'),
          icon: Iconsax.note_text,
        ),
        const SizedBox(height: AppSpacing.lg),
        // Photo du bon (obligatoire)
        GestureDetector(
          onTap: _showPhotoSourceSheet,
          child: Container(
            width: double.infinity,
            height: _receiptPhotoBytes != null ? 200 : 120,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: _receiptPhotoBytes != null ? AppColors.success : AppColors.error,
                width: 2,
              ),
            ),
            child: _receiptPhotoBytes != null
                ? Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.lg - 2),
                        child: Image.memory(
                          _receiptPhotoBytes!,
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: AppSpacing.sm,
                        right: AppSpacing.sm,
                        child: IconButton(
                          onPressed: () => setState(() {
                            _receiptPhoto = null;
                            _receiptPhotoBytes = null;
                          }),
                          icon: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Iconsax.close_circle, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.camera, color: AppColors.error, size: 40),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '${l10n.translate('fuel.takePhoto')} *',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: AppSpacing.md),
          Container(
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
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        // Bouton de confirmation
        SizedBox(
          width: double.infinity,
          height: 72,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitFuelEntry,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: _isSubmitting
                ? const CircularProgressIndicator(color: Colors.white)
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Iconsax.tick_circle, color: Colors.white, size: 32),
                      const SizedBox(width: AppSpacing.md),
                      Text(
                        l10n.translate('fuel.confirm'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivitiesList(AppLocalizations l10n, UserModel user) {
    final requestsAsync =
        ref.watch(fulfilledByUserRequestsStreamProvider(user.id));

    return requestsAsync.when(
      data: (requests) {
        if (requests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.activity,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    size: 64),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  l10n.translate('fuel.noActivities'),
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
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            return _buildActivityCard(l10n, request);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (error, _) => Center(
        child: Text(
          '${l10n.translate('common.error')}: $error',
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildActivityCard(AppLocalizations l10n, FuelRequestModel request) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (request.status) {
      case FuelRequestStatus.fulfilled:
        statusColor = AppColors.info;
        statusLabel = l10n.translate('fuelRequest.fulfilled');
        statusIcon = Iconsax.timer;
      case FuelRequestStatus.validated:
        statusColor = AppColors.success;
        statusLabel = l10n.translate('fuelRequest.validated');
        statusIcon = Iconsax.tick_circle;
      case FuelRequestStatus.disputed:
        statusColor = AppColors.error;
        statusLabel = l10n.translate('fuelRequest.disputed');
        statusIcon = Iconsax.warning_2;
      case FuelRequestStatus.pending:
        statusColor = AppColors.warning;
        statusLabel = l10n.translate('fuelRequest.pending');
        statusIcon = Iconsax.clock;
      case FuelRequestStatus.rejected:
        statusColor = AppColors.error;
        statusLabel = l10n.translate('fuelRequest.rejected');
        statusIcon = Iconsax.close_circle;
      case FuelRequestStatus.cancelled:
        statusColor = AppColors.textTertiary;
        statusLabel = l10n.translate('fuelRequest.cancelled');
        statusIcon = Iconsax.close_circle;
    }

    return InkWell(
      onTap: () => FuelRequestDetailSheet.show(context, request),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
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
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(Iconsax.truck, color: statusColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.truckImmatriculation,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${l10n.translate('fuelRequest.requestedBy')}: ${request.requestedByName}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              const Icon(Iconsax.gas_station,
                  color: AppColors.textSecondary, size: 18),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${l10n.translate('fuelRequest.fulfilledLiters')}: ${request.fulfilledLiters?.toStringAsFixed(1) ?? '-'} L',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (request.receiptNumber != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Iconsax.receipt_2,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.translate('fuel.receiptNumber')}: ${request.receiptNumber}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (request.fulfilledAt != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Iconsax.calendar_1,
                    color: AppColors.textSecondary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${l10n.translate('fuel.fulfilledAt')}: '
                  '${request.fulfilledAt!.day.toString().padLeft(2, '0')}/'
                  '${request.fulfilledAt!.month.toString().padLeft(2, '0')}/'
                  '${request.fulfilledAt!.year} '
                  '${request.fulfilledAt!.hour.toString().padLeft(2, '0')}:'
                  '${request.fulfilledAt!.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
          if (request.observation != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Iconsax.note_text,
                      color: AppColors.warning, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${l10n.translate('fuel.observation')}: ${request.observation}',
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (request.status == FuelRequestStatus.validated &&
              request.isAutoValidated) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Iconsax.tick_circle,
                    color: AppColors.success, size: 14),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.translate('fuel.autoValidated'),
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (request.status == FuelRequestStatus.disputed &&
              request.disputeReason != null) ...[
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
                children: [
                  const Icon(Iconsax.warning_2,
                      color: AppColors.error, size: 16),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      request.disputeReason!,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            '${request.formattedDate} ${request.formattedTime}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    double fontSize = 18,
    String? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        inputFormatters: inputFormatters,
        style: TextStyle(
          color: AppColors.textPrimary,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 16,
          ),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 28),
          suffixText: suffix,
          suffixStyle: TextStyle(
            color: AppColors.textSecondary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(AppSpacing.lg),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
