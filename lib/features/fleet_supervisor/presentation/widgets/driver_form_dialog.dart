import 'dart:io' show File; // utilisé pour FileImage sur mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../services/image_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';
import '../../../users/data/repositories/user_management_repository.dart';
import '../../../users/presentation/providers/user_management_providers.dart';

/// Dialog de création ou d'édition d'un chauffeur avec photo de profil.
/// [driver] null → création  |  non-null → édition
class DriverFormDialog extends ConsumerStatefulWidget {
  const DriverFormDialog({
    this.driver,
    this.fleetId,
    super.key,
  });

  final UserModel? driver;
  final String? fleetId;

  @override
  ConsumerState<DriverFormDialog> createState() => _DriverFormDialogState();
}

class _DriverFormDialogState extends ConsumerState<DriverFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _licenseCtrl;

  XFile? _profilePhoto;
  bool _photoChanged = false;
  final _imageService = ImageService();
  bool _isLoading = false;

  bool get _isEditMode => widget.driver != null;

  @override
  void initState() {
    super.initState();
    final d = widget.driver;
    _firstNameCtrl = TextEditingController(text: d?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: d?.lastName ?? '');
    _phoneCtrl = TextEditingController(text: d?.phoneNumber ?? '');
    _addressCtrl = TextEditingController(text: d?.address ?? '');
    _licenseCtrl =
        TextEditingController(text: d?.driverLicenseNumber ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _licenseCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Photo de profil',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: AppColors.primary),
              title: const Text('Prendre une photo',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _imageService.pickFromCamera();
                if (file != null && mounted) {
                  setState(() {
                    _profilePhoto = file;
                    _photoChanged = true;
                  });
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.primary),
              title: const Text('Choisir depuis la galerie',
                  style: TextStyle(color: AppColors.textPrimary)),
              onTap: () async {
                Navigator.pop(ctx);
                final file = await _imageService.pickFromGallery();
                if (file != null && mounted) {
                  setState(() {
                    _profilePhoto = file;
                    _photoChanged = true;
                  });
                }
              },
            ),
            if (widget.driver?.photoUrl != null || _profilePhoto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: const Text('Supprimer la photo',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _profilePhoto = null;
                    _photoChanged = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(userManagementRepositoryProvider);

      if (_isEditMode) {
        await _handleEdit(repo);
      } else {
        await _handleCreate(repo);
      }

      if (widget.fleetId != null) {
        ref.invalidate(fleetDriversProvider(widget.fleetId!));
      }
      ref.invalidate(allUsersProvider);

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleCreate(UserManagementRepository repo) async {
    final newDriver = await repo.createDriver(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phoneNumber:
          _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      driverLicenseNumber: _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
      fleetId: widget.fleetId,
    );

    if (_profilePhoto != null) {
      final photoUrl = await _imageService.uploadXFile(
        _profilePhoto!,
        'users/${newDriver.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await repo.updateUserBasicInfo(
          userId: newDriver.id, photoUrl: photoUrl);
    }
  }

  Future<void> _handleEdit(UserManagementRepository repo) async {
    final driver = widget.driver!;
    String? newPhotoUrl;

    if (_photoChanged) {
      if (_profilePhoto != null) {
        newPhotoUrl = await _imageService.uploadXFile(
          _profilePhoto!,
          'users/${driver.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        if (driver.photoUrl != null && driver.photoUrl!.isNotEmpty) {
          await _imageService.deleteByUrl(driver.photoUrl!);
        }
      } else {
        newPhotoUrl = '';
        if (driver.photoUrl != null && driver.photoUrl!.isNotEmpty) {
          await _imageService.deleteByUrl(driver.photoUrl!);
        }
      }
    }

    await repo.updateUserBasicInfo(
      userId: driver.id,
      firstName: _firstNameCtrl.text.trim().isEmpty
          ? null
          : _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim().isEmpty
          ? null
          : _lastNameCtrl.text.trim(),
      phoneNumber: _phoneCtrl.text.trim().isEmpty
          ? null
          : _phoneCtrl.text.trim(),
      address: _addressCtrl.text.trim().isEmpty
          ? null
          : _addressCtrl.text.trim(),
      driverLicenseNumber: _licenseCtrl.text.trim().isEmpty
          ? null
          : _licenseCtrl.text.trim(),
      photoUrl: newPhotoUrl,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final driver = widget.driver;
    final hasNetworkPhoto =
        driver?.photoUrl != null && driver!.photoUrl!.isNotEmpty;

    final initials = driver != null
        ? driver.initials.isNotEmpty
            ? driver.initials
            : '?'
        : (_firstNameCtrl.text.isNotEmpty
            ? _firstNameCtrl.text[0].toUpperCase()
            : '?');

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
          maxWidth: 520,
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Row(
              children: [
                // Avatar photo tappable
                GestureDetector(
                  onTap: _pickPhoto,
                  child: Stack(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: _profilePhoto != null
                              ? (kIsWeb
                                  ? Image.network(_profilePhoto!.path, fit: BoxFit.cover)
                                  : Image.file(File(_profilePhoto!.path), fit: BoxFit.cover))
                              : hasNetworkPhoto
                                  ? Image.network(
                                      driver.photoUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Center(
                                        child: Text(
                                          initials,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Center(
                                      child: _isEditMode
                                          ? Text(
                                              initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 24,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            )
                                          : const Icon(Iconsax.user_add,
                                              color: Colors.white, size: 30),
                                    ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.surface, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isEditMode
                            ? l10n.translate('fleet.editDriver')
                            : l10n.translate('fleet.createDriver'),
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _isEditMode
                            ? ((driver?.fullName.isNotEmpty ?? false)
                                ? driver!.fullName
                                : driver?.matricule ?? '')
                            : l10n.translate('fleet.newDriverSubtitle'),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            const Divider(color: AppColors.surfaceBorder, height: 1),
            const SizedBox(height: AppSpacing.lg),
            // ── Formulaire ────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _firstNameCtrl,
                              label: l10n.translate(
                                  'users.createUserDialog.firstName'),
                              icon: Iconsax.user,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: _Field(
                              controller: _lastNameCtrl,
                              label: l10n.translate(
                                  'users.createUserDialog.lastName'),
                              icon: Iconsax.user,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Champ requis'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Field(
                        controller: _phoneCtrl,
                        label: l10n
                            .translate('users.createUserDialog.phone'),
                        icon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Field(
                        controller: _licenseCtrl,
                        label: 'Numéro de permis',
                        icon: Iconsax.card,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _Field(
                        controller: _addressCtrl,
                        label: l10n
                            .translate('users.createUserDialog.address'),
                        icon: Iconsax.location,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // ── Actions ───────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed:
                      _isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    l10n.translate('common.cancel'),
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submit,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : Icon(
                          _isEditMode ? Iconsax.tick_circle : Iconsax.user_add,
                          size: 18),
                  label: Text(
                    _isEditMode
                        ? l10n.translate('common.save')
                        : l10n.translate('common.create'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl, vertical: AppSpacing.md),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Champ de formulaire ──────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.backgroundSecondary,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
    );
  }
}
