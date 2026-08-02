import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../../services/image_service.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../../../users/presentation/providers/user_management_providers.dart';

/// Dialogue d'édition d'un chauffeur (sans modification de compte Firebase Auth)
class EditDriverDialog extends ConsumerStatefulWidget {
  const EditDriverDialog({required this.driver, super.key});

  final UserModel driver;

  @override
  ConsumerState<EditDriverDialog> createState() => _EditDriverDialogState();
}

class _EditDriverDialogState extends ConsumerState<EditDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _licenseController;

  String? _selectedManagerId;
  String? _selectedManagerName;
  bool _isLoading = false;
  XFile? _newPhoto;
  bool _photoChanged = false;
  final _imageService = ImageService();

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.driver.firstName);
    _lastNameController = TextEditingController(text: widget.driver.lastName);
    _phoneController = TextEditingController(text: widget.driver.phoneNumber ?? '');
    _addressController = TextEditingController(text: widget.driver.address ?? '');
    _licenseController =
        TextEditingController(text: widget.driver.driverLicenseNumber ?? '');
    _selectedManagerId = widget.driver.managerId;
    _selectedManagerName = widget.driver.managerName;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final l10n = AppLocalizations.of(context);
    final hasPhoto = _newPhoto != null ||
        (widget.driver.photoUrl != null &&
            widget.driver.photoUrl!.isNotEmpty &&
            !_photoChanged);

    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
              title: Text(l10n.translate('photos.camera')),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: Text(l10n.translate('photos.gallery')),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            if (hasPhoto)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: AppColors.error),
                title: Text(l10n.translate('driverManagement.removePhoto'),
                    style: const TextStyle(color: AppColors.error)),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
    if (choice == 'camera') {
      final file = await _imageService.pickFromCamera();
      if (file != null && mounted) {
        setState(() { _newPhoto = file; _photoChanged = true; });
      }
    } else if (choice == 'gallery') {
      final file = await _imageService.pickFromGallery();
      if (file != null && mounted) {
        setState(() { _newPhoto = file; _photoChanged = true; });
      }
    } else if (choice == 'remove') {
      setState(() { _newPhoto = null; _photoChanged = true; });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final repository = ref.read(userManagementRepositoryProvider);

      // Gestion de la photo
      String? newPhotoUrl;
      if (_photoChanged) {
        if (_newPhoto != null) {
          newPhotoUrl = await _imageService.uploadXFile(
            _newPhoto!,
            'users/${widget.driver.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          if (widget.driver.photoUrl != null && widget.driver.photoUrl!.isNotEmpty) {
            await _imageService.deleteByUrl(widget.driver.photoUrl!);
          }
        } else {
          newPhotoUrl = '';
          if (widget.driver.photoUrl != null && widget.driver.photoUrl!.isNotEmpty) {
            await _imageService.deleteByUrl(widget.driver.photoUrl!);
          }
        }
      }

      final updates = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phoneNumber': _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        'address': _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        'driverLicenseNumber': _licenseController.text.trim().isEmpty
            ? null
            : _licenseController.text.trim(),
        'managerId': _selectedManagerId,
        'managerName': _selectedManagerName,
        if (newPhotoUrl != null)
          'photoUrl': newPhotoUrl.isEmpty ? null : newPhotoUrl,
      };

      await repository.updateUserFields(widget.driver.id, updates);
      ref.invalidate(allUsersProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('driverManagement.editSuccess')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n
                .translate('driverManagement.editError')
                .replaceAll('{error}', e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isSmall = size.width < 600;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: isSmall ? size.width * 0.95 : 560,
        constraints: BoxConstraints(maxHeight: size.height * 0.9),
        padding: EdgeInsets.all(isSmall ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(l10n),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Avatar photo ──────────────────────────────
                      Center(
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              _buildAvatarPreview(),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
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
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Nom / Prénom
                      Row(
                        children: [
                          Expanded(
                            child: PremiumTextField(
                              controller: _firstNameController,
                              label: l10n.translate(
                                  'users.createUserDialog.firstName'),
                              hint: l10n.translate(
                                  'users.createUserDialog.firstNameHint'),
                              prefixIcon: Iconsax.user,
                              validator: (v) => Validators.name(v,
                                  fieldName: l10n.translate(
                                      'users.createUserDialog.firstName')),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: PremiumTextField(
                              controller: _lastNameController,
                              label: l10n.translate(
                                  'users.createUserDialog.lastName'),
                              hint: l10n.translate(
                                  'users.createUserDialog.lastNameHint'),
                              prefixIcon: Iconsax.user,
                              validator: (v) => Validators.name(v,
                                  fieldName: l10n.translate(
                                      'users.createUserDialog.lastName')),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Téléphone
                      PremiumTextField(
                        controller: _phoneController,
                        label: l10n.translate('driverManagement.phone'),
                        hint:
                            l10n.translate('users.createUserDialog.phoneHint'),
                        prefixIcon: Iconsax.call,
                        keyboardType: TextInputType.phone,
                        validator: Validators.optionalPhoneNumber,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Adresse
                      PremiumTextField(
                        controller: _addressController,
                        label:
                            l10n.translate('users.createUserDialog.address'),
                        hint: l10n
                            .translate('users.createUserDialog.addressHint'),
                        prefixIcon: Iconsax.location,
                        maxLines: 2,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Numéro de permis
                      PremiumTextField(
                        controller: _licenseController,
                        label: l10n
                            .translate('users.createUserDialog.driverLicense'),
                        hint: l10n.translate(
                            'users.createUserDialog.driverLicenseHint'),
                        prefixIcon: Iconsax.card,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Responsable
                      _buildManagerSelector(l10n),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildActions(l10n),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarPreview() {
    const double size = 88;
    Widget imageWidget;

    if (_newPhoto != null) {
      imageWidget = kIsWeb
          ? Image.network(_newPhoto!.path,
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsCircle(size))
          : Image.file(File(_newPhoto!.path),
              width: size, height: size, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initialsCircle(size));
    } else if (!_photoChanged &&
        widget.driver.photoUrl != null &&
        widget.driver.photoUrl!.isNotEmpty) {
      imageWidget = Image.network(
        widget.driver.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initialsCircle(size),
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : _initialsCircle(size),
      );
    } else {
      imageWidget = _initialsCircle(size);
    }

    return ClipOval(child: imageWidget);
  }

  Widget _initialsCircle(double size) {
    return Container(
      width: size,
      height: size,
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          widget.driver.initials,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppLocalizations l10n) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: const Icon(Iconsax.edit, color: Colors.white),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.translate('driverManagement.editTitle'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.driver.fullName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildManagerSelector(AppLocalizations l10n) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.user_octagon,
                  color: AppColors.textSecondary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('management.assignManager'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          if (_selectedManagerName != null) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                        child:
                            Icon(Iconsax.user, color: Colors.white, size: 16)),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _selectedManagerName!,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle,
                        color: AppColors.error, size: 20),
                    onPressed: () => setState(() {
                      _selectedManagerId = null;
                      _selectedManagerName = null;
                    }),
                  ),
                ],
              ),
            ),
          ] else ...[
            allUsersAsync.when(
              data: (users) {
                final managers = users
                    .where((u) =>
                        u.isActive &&
                        u.role?.toLowerCase() != 'chauffeur' &&
                        u.id != widget.driver.id)
                    .toList();
                return DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.surface,
                  hint: Text(
                    l10n.translate('management.selectManager'),
                    style: const TextStyle(
                        color: AppColors.textTertiary, fontSize: 14),
                  ),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  items: managers
                      .map((u) => DropdownMenuItem(
                            value: u.id,
                            child: Text(
                              '${u.fullName} (${u.role ?? ""})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (id) {
                    if (id != null) {
                      final selected =
                          managers.firstWhere((u) => u.id == id);
                      setState(() {
                        _selectedManagerId = selected.id;
                        _selectedManagerName = selected.fullName;
                      });
                    }
                  },
                );
              },
              loading: () => const SizedBox(
                height: 40,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (_, __) => InlineErrorRetry(
                onRetry: () => ref.invalidate(allUsersProvider),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('common.cancel'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        PremiumButton(
          text: l10n.translate('common.save'),
          onPressed: _handleSave,
          isLoading: _isLoading,
          icon: Iconsax.tick_circle,
        ),
      ],
    );
  }
}
