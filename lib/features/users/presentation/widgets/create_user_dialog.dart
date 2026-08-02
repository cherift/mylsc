import 'dart:io' show File; // utilisé pour FileImage sur mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/validators.dart';
import '../../../../services/image_service.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart';
import '../providers/user_management_providers.dart';

/// Dialogue de création d'un nouvel utilisateur
class CreateUserDialog extends ConsumerStatefulWidget {
  const CreateUserDialog({super.key});

  @override
  ConsumerState<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends ConsumerState<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();

  String _selectedRole = 'Superviseur Flotte';
  String? _selectedDepartment;
  DateTime? _selectedDateOfBirth;
  bool _isLoading = false;

  // Photo de profil
  XFile? _profilePhoto;
  final _imageService = ImageService();

  static const List<String> _departments = [
    'Direction Générale',
    'Direction des opérations',
    'Direction des contrôles et suivi logistique',
    'Direction Technique',
  ];

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(1990),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
            dialogTheme: const DialogThemeData(
              backgroundColor: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() => _selectedDateOfBirth = date);
    }
  }

  Future<void> _pickPhoto() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.backgroundSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
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
                  setState(() => _profilePhoto = file);
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
                  setState(() => _profilePhoto = file);
                }
              },
            ),
            if (_profilePhoto != null)
              ListTile(
                leading: const Icon(Icons.delete_outline,
                    color: AppColors.error),
                title: const Text('Supprimer la photo',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  setState(() => _profilePhoto = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validation croisée : au moins un des deux requis
    if (email.isEmpty && phone.isEmpty) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.translate('users.createUserDialog.emailOrPhoneRequired')),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(userManagementRepositoryProvider);

      final newUser = await repository.createUser(
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        role: _selectedRole,
        email: email.isEmpty ? null : email,
        phoneNumber: phone.isEmpty ? null : phone,
        department: _selectedRole == 'Direction' ? _selectedDepartment : null,
        address: _addressController.text.trim().isEmpty
            ? null
            : _addressController.text.trim(),
        driverLicenseNumber: _licenseController.text.trim().isEmpty
            ? null
            : _licenseController.text.trim(),
        dateOfBirth: _selectedDateOfBirth,
      );

      // Upload photo si sélectionnée
      if (_profilePhoto != null) {
        final photoUrl = await _imageService.uploadXFile(
          _profilePhoto!,
          'users/${newUser.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
        );
        await repository.updateUserBasicInfo(
          userId: newUser.id,
          photoUrl: photoUrl,
        );
      }

      // Rafraîchir la liste des utilisateurs
      ref.invalidate(allUsersProvider);
      ref.invalidate(userStatsProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('users.createUserDialog.success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('users.createUserDialog.error').replaceAll('{error}', e.toString())),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;
    final isMediumScreen = size.width >= 600 && size.width < 900;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Container(
        width: isSmallScreen ? size.width * 0.95 : (isMediumScreen ? 700 : 800),
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9,
          maxWidth: 900,
        ),
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.xl),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(l10n.translate('users.createUserDialog.personalInfo'), [
                        Row(
                          children: [
                            Expanded(child: _buildFirstNameField(l10n)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildLastNameField(l10n)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            Expanded(child: _buildEmailField(l10n)),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _buildPhoneField(l10n)),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          l10n.translate('users.createUserDialog.emailOrPhoneHint'),
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildDateOfBirthField(l10n),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSection(l10n.translate('users.createUserDialog.professionalInfo'), [
                        Row(
                          children: [
                            Expanded(child: _buildRoleField(l10n)),
                            if (_selectedRole == 'Direction') ...[
                              const SizedBox(width: AppSpacing.md),
                              Expanded(child: _buildDepartmentField(l10n)),
                            ],
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        _buildAddressField(l10n),
                      ]),
                      const SizedBox(height: AppSpacing.lg),
                      _buildSection(l10n.translate('users.createUserDialog.security'), [
                        _buildPasswordField(l10n),
                      ]),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: isSmallScreen ? AppSpacing.md : AppSpacing.xl),
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        // Avatar photo tappable
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: _profilePhoto != null
                      ? (kIsWeb
                          ? Image.network(_profilePhoto!.path, fit: BoxFit.cover)
                          : Image.file(File(_profilePhoto!.path), fit: BoxFit.cover))
                      : const Icon(Iconsax.user_add,
                          color: Colors.white, size: 28),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppColors.surface, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 12),
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
                l10n.translate('users.createUserDialog.title'),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n.translate('users.createUserDialog.subtitle'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
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

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildFirstNameField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _firstNameController,
      label: l10n.translate('users.createUserDialog.firstName'),
      hint: l10n.translate('users.createUserDialog.firstNameHint'),
      prefixIcon: Iconsax.user,
      validator: (value) => Validators.name(value, fieldName: l10n.translate('users.createUserDialog.firstName')),
    );
  }

  Widget _buildLastNameField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _lastNameController,
      label: l10n.translate('users.createUserDialog.lastName'),
      hint: l10n.translate('users.createUserDialog.lastNameHint'),
      prefixIcon: Iconsax.user,
      validator: (value) => Validators.name(value, fieldName: l10n.translate('users.createUserDialog.lastName')),
    );
  }

  Widget _buildEmailField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _emailController,
      label: '${l10n.translate('users.createUserDialog.email')} (optionnel)',
      hint: l10n.translate('users.createUserDialog.emailHint'),
      prefixIcon: Iconsax.sms,
      keyboardType: TextInputType.emailAddress,
      validator: Validators.optionalEmail,
    );
  }

  Widget _buildPhoneField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _phoneController,
      label: '${l10n.translate('users.createUserDialog.phone')} (optionnel)',
      hint: l10n.translate('users.createUserDialog.phoneHint'),
      prefixIcon: Iconsax.call,
      keyboardType: TextInputType.phone,
      validator: Validators.optionalPhoneNumber,
    );
  }

  Widget _buildDateOfBirthField(AppLocalizations l10n) {
    return GestureDetector(
      onTap: _selectDate,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          children: [
            const Icon(Iconsax.calendar, color: AppColors.textTertiary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                _selectedDateOfBirth == null
                    ? l10n.translate('users.createUserDialog.dateOfBirth')
                    : '${_selectedDateOfBirth!.day}/${_selectedDateOfBirth!.month}/${_selectedDateOfBirth!.year}',
                style: TextStyle(
                  color: _selectedDateOfBirth == null
                      ? AppColors.textTertiary
                      : AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleField(AppLocalizations l10n) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.user_tag, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedRole,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: [
                    'Superviseur Flotte',
                    'Superviseur Général',
                    'Superviseur Mine',
                    'Superviseur Port',
                    'RH',
                    'Direction',
                    'Pompiste',
                    'Chef Ravitaillement',
                    'Responsable Approvisionnement',
                    'Responsable Opérations',
                    'Centre Technique',
                  ]
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(_translateRole(role, l10n)),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedRole = value ?? 'Superviseur Flotte'),
            ),
          ),
        ],
      ),
    );
  }

  String _translateRole(String role, AppLocalizations l10n) {
    switch (role) {
      case 'Chauffeur':
        return l10n.translate('users.roles.chauffeur');
      case 'Superviseur Flotte':
        return l10n.translate('users.roles.superviseurFlotte');
      case 'Superviseur Général':
        return l10n.translate('users.roles.superviseurGeneral');
      case 'Superviseur Mine':
        return l10n.translate('users.roles.superviseurMine');
      case 'Superviseur Port':
        return l10n.translate('users.roles.superviseurPort');
      case 'RH':
        return l10n.translate('users.roles.rh');
      case 'Direction':
        return l10n.translate('users.roles.direction');
      case 'Pompiste':
        return l10n.translate('users.roles.pompiste');
      case 'Chef Ravitaillement':
        return l10n.translate('users.roles.chefRavitaillement');
      case 'Responsable Approvisionnement':
        return l10n.translate('users.roles.responsableApprovisionnement');
      case 'Responsable Opérations':
        return l10n.translate('users.roles.responsableOperations');
      case 'Centre Technique':
        return l10n.translate('users.roles.centreTechnique');
      default:
        return role;
    }
  }

  Widget _buildDepartmentField(AppLocalizations l10n) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(Iconsax.building, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: DropdownButton<String>(
              value: _selectedDepartment,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              dropdownColor: AppColors.surface,
              hint: Text(
                l10n.translate('users.createUserDialog.department'),
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
              ),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: _departments
                  .map((dept) => DropdownMenuItem(
                        value: dept,
                        child: Text(dept),
                      ))
                  .toList(),
              onChanged: (value) => setState(() => _selectedDepartment = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _addressController,
      label: l10n.translate('users.createUserDialog.address'),
      hint: l10n.translate('users.createUserDialog.addressHint'),
      prefixIcon: Iconsax.location,
      maxLines: 2,
    );
  }

  Widget _buildPasswordField(AppLocalizations l10n) {
    return PremiumTextField(
      controller: _passwordController,
      label: l10n.translate('users.createUserDialog.temporaryPassword'),
      hint: l10n.translate('users.createUserDialog.temporaryPasswordHint'),
      prefixIcon: Iconsax.lock,
      obscureText: true,
      validator: Validators.password,
    );
  }

  Widget _buildActions() {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(
            l10n.translate('users.createUserDialog.cancel'),
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
        PremiumButton(
          text: l10n.translate('users.createUserDialog.create'),
          onPressed: _handleCreateUser,
          isLoading: _isLoading,
          icon: Iconsax.tick_circle,
        ),
      ],
    );
  }
}
