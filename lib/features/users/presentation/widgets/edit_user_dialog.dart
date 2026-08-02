import 'dart:io' show File; // utilisé pour FileImage sur mobile
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../services/image_service.dart';
import '../../../auth/domain/models/permission.dart';
import '../../../auth/domain/models/role.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../auth/presentation/providers/permission_providers.dart';
import '../providers/user_management_providers.dart';

/// Dialogue d'édition d'un utilisateur avec onglets
class EditUserDialog extends ConsumerStatefulWidget {

  const EditUserDialog({required this.user, super.key});
  final UserModel user;

  @override
  ConsumerState<EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<EditUserDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedRole;
  String? _selectedDepartment;
  late Set<Permission> _selectedPermissions;
  final _reasonController = TextEditingController();
  bool _hasChanges = false;
  bool _isLoading = false;

  static const List<String> _departments = [
    'Direction Générale',
    'Direction des opérations',
    'Direction des contrôles et suivi logistique',
    'Direction Technique',
  ];

  // Manager
  String? _selectedManagerId;
  String? _selectedManagerName;
  bool _managerChanged = false;

  // Photo de profil
  XFile? _profilePhoto;
  bool _photoChanged = false;
  final _imageService = ImageService();

  // Contrôleurs pour les infos de base
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _licenseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedRole = widget.user.role ?? 'Superviseur Flotte';
    _selectedDepartment = widget.user.department;

    // Récupérer seulement les permissions additionnelles (pas celles du rôle)
    final service = ref.read(permissionServiceProvider);
    _selectedPermissions = service.getAdditionalPermissions(widget.user);

    // Initialiser le manager
    _selectedManagerId = widget.user.managerId;
    _selectedManagerName = widget.user.managerName;

    // Initialiser les contrôleurs
    _firstNameController.text = widget.user.firstName ?? '';
    _lastNameController.text = widget.user.lastName ?? '';
    _phoneController.text = widget.user.phoneNumber ?? '';
    _addressController.text = widget.user.address ?? '';
    _licenseController.text = widget.user.driverLicenseNumber ?? '';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _reasonController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _licenseController.dispose();
    super.dispose();
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
        width: isSmallScreen ? size.width * 0.95 : (isMediumScreen ? 800 : 900),
        constraints: BoxConstraints(
          maxHeight: size.height * 0.9,
          maxWidth: 1000,
        ),
        padding: EdgeInsets.all(isSmallScreen ? AppSpacing.md : AppSpacing.xl),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.lg),
            _buildTabBar(l10n),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildBasicInfoTab(l10n),
                  _buildRolePermissionsTab(l10n),
                  _buildHistoryTab(l10n),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            _buildActions(l10n),
          ],
        ),
      ),
    );
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
                  setState(() {
                    _profilePhoto = file;
                    _photoChanged = true;
                    _hasChanges = true;
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
                    _hasChanges = true;
                  });
                }
              },
            ),
            if (widget.user.photoUrl != null || _profilePhoto != null)
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
                    _hasChanges = true;
                  });
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    final hasNetworkPhoto =
        widget.user.photoUrl != null && widget.user.photoUrl!.isNotEmpty;

    return Row(
      children: [
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
                      : hasNetworkPhoto
                          ? Image.network(
                              widget.user.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Text(
                                  widget.user.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                widget.user.initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
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
                    border: Border.all(
                        color: AppColors.surface, width: 2),
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
                widget.user.fullName.isEmpty
                    ? widget.user.email
                    : widget.user.fullName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                widget.user.matricule ?? l10n.translate('users.matricule'),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Iconsax.close_square, color: AppColors.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildTabBar(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        dividerColor: Colors.transparent,
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        indicatorPadding: const EdgeInsets.all(4),
        tabs: [
          Tab(
            height: 48,
            child: Center(child: Text(l10n.translate('users.createUserDialog.personalInfo'))),
          ),
          const Tab(
            height: 48,
            child: Center(child: Text('Rôle & Permissions')),
          ),
          const Tab(
            height: 48,
            child: Center(child: Text('Historique')),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(AppLocalizations l10n) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(
            controller: _firstNameController,
            label: l10n.translate('users.createUserDialog.firstName'),
            icon: Iconsax.user,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _lastNameController,
            label: l10n.translate('users.createUserDialog.lastName'),
            icon: Iconsax.user,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _phoneController,
            label: l10n.translate('users.createUserDialog.phone'),
            icon: Iconsax.call,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField(
            controller: _addressController,
            label: l10n.translate('users.createUserDialog.address'),
            icon: Iconsax.location,
            maxLines: 2,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildManagerSelector(l10n),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Informations non modifiables',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildReadOnlyField(l10n.translate('users.createUserDialog.email'), widget.user.email),
                _buildReadOnlyField(l10n.translate('users.matricule'), widget.user.matricule ?? 'N/A'),
                _buildReadOnlyField(
                  l10n.translate('users.createdOn'),
                  '${widget.user.createdAt.day}/${widget.user.createdAt.month}/${widget.user.createdAt.year}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolePermissionsTab(AppLocalizations l10n) {
    // Vérifier si l'utilisateur modifie son propre profil
    final currentUser = ref.watch(authControllerProvider).value;
    final isEditingSelf = currentUser?.id == widget.user.id;
    final canManagePermissions = currentUser?.hasPermission(Permission.managePermissions) ?? false;

    // L'utilisateur ne peut pas modifier ses propres rôles/permissions sauf s'il a managePermissions
    final canEditRoleAndPermissions = !isEditingSelf || canManagePermissions;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!canEditRoleAndPermissions) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.warning),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.info_circle, color: AppColors.warning, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Vous ne pouvez pas modifier vos propres rôles et permissions. Contactez un administrateur avec la permission "Gérer les permissions".',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          _buildRoleSelector(l10n, enabled: canEditRoleAndPermissions),
          if (_selectedRole == 'Direction') ...[
            const SizedBox(height: AppSpacing.md),
            _buildDepartmentSelector(l10n, enabled: canEditRoleAndPermissions),
          ],
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Permissions additionnelles',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Les permissions du rôle sont automatiquement incluses. Ajoutez des permissions supplémentaires si nécessaire.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildPermissionsList(enabled: canEditRoleAndPermissions),
          const SizedBox(height: AppSpacing.lg),
          _buildReasonField(l10n),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(AppLocalizations l10n) {
    final historyAsync = ref.watch(userPermissionHistoryMapProvider(widget.user.id));

    return historyAsync.when(
      data: (List<Map<String, dynamic>> history) {
        if (history.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Iconsax.note, size: 64, color: AppColors.textTertiary),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Aucun historique disponible',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: history.length,
          itemBuilder: (context, index) => _buildHistoryItem(history[index]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, _) => Center(
        child: Text(
          l10n.translate('users.createUserDialog.error').replaceAll('{error}', error.toString()),
          style: const TextStyle(color: AppColors.error),
        ),
      ),
    );
  }

  Widget _buildManagerSelector(AppLocalizations l10n) {
    final allUsersAsync = ref.watch(allUsersProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: _managerChanged ? AppColors.info : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Iconsax.user_octagon, color: AppColors.textSecondary, size: 20),
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
                      child: Icon(Iconsax.user, color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      _selectedManagerName!,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.close_circle, color: AppColors.error, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedManagerId = null;
                        _selectedManagerName = null;
                        _managerChanged = true;
                        _hasChanges = true;
                      });
                    },
                    tooltip: l10n.translate('management.managerRemoved'),
                  ),
                ],
              ),
            ),
          ] else ...[
            allUsersAsync.when(
              data: (users) {
                // Exclure l'utilisateur courant de la liste
                final availableManagers = users
                    .where((u) => u.id != widget.user.id && u.isActive)
                    .toList();

                return DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  dropdownColor: AppColors.surface,
                  hint: Text(
                    l10n.translate('management.selectManager'),
                    style: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  items: availableManagers
                      .map((user) => DropdownMenuItem(
                            value: user.id,
                            child: Text(
                              '${user.fullName} (${user.role ?? "N/A"})',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      final selected = availableManagers.firstWhere((u) => u.id == value);
                      setState(() {
                        _selectedManagerId = selected.id;
                        _selectedManagerName = selected.fullName;
                        _managerChanged = true;
                        _hasChanges = true;
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
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (_, __) => Text(
                l10n.translate('common.error'),
                style: const TextStyle(color: AppColors.error, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoleSelector(AppLocalizations l10n, {bool enabled = true}) {
    final currentRole = widget.user.role ?? 'Superviseur Flotte';
    final hasRoleChanged = _selectedRole != currentRole;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: enabled ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasRoleChanged ? AppColors.warning : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.user_tag, color: enabled ? AppColors.textSecondary : AppColors.textTertiary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Rôle principal',
                style: TextStyle(
                  color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButton<String>(
            value: _selectedRole,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            style: TextStyle(color: enabled ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 14),
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
            onChanged: enabled ? (value) {
              setState(() {
                _selectedRole = value ?? 'Superviseur Flotte';
                _hasChanges = true;
              });
            } : null,
          ),
          if (hasRoleChanged) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Row(
                children: [
                  Icon(Iconsax.warning_2, color: AppColors.warning, size: 16),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Le changement de rôle générera un nouveau matricule',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
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

  Widget _buildDepartmentSelector(AppLocalizations l10n, {bool enabled = true}) {
    final currentDepartment = widget.user.department;
    final hasDepartmentChanged = _selectedDepartment != currentDepartment;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: enabled ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: hasDepartmentChanged ? AppColors.info : AppColors.surfaceBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Iconsax.building, color: enabled ? AppColors.textSecondary : AppColors.textTertiary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.translate('users.createUserDialog.department'),
                style: TextStyle(
                  color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DropdownButton<String>(
            value: _selectedDepartment,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: AppColors.surface,
            hint: Text(
              'Sélectionner un département',
              style: TextStyle(color: enabled ? AppColors.textTertiary : AppColors.textTertiary.withValues(alpha: 0.5), fontSize: 14),
            ),
            style: TextStyle(color: enabled ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 14),
            items: _departments
                .map((dept) => DropdownMenuItem(
                      value: dept,
                      child: Text(dept),
                    ))
                .toList(),
            onChanged: enabled ? (value) {
              setState(() {
                _selectedDepartment = value;
                _hasChanges = true;
              });
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsList({bool enabled = true}) {
    final permissionsByCategory = <PermissionCategory, List<Permission>>{};

    for (final category in PermissionCategory.values) {
      permissionsByCategory[category] = Permission.values
          .where((p) => p.category == category)
          .toList();
    }

    return Column(
      children: permissionsByCategory.entries.map((entry) {
        return _buildPermissionCategory(entry.key, entry.value, enabled: enabled);
      }).toList(),
    );
  }

  Widget _buildPermissionCategory(PermissionCategory category, List<Permission> permissions, {bool enabled = true}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: enabled ? AppColors.backgroundSecondary : AppColors.backgroundSecondary.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(category.icon, color: enabled ? category.color : AppColors.textTertiary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              category.displayName,
              style: TextStyle(
                color: enabled ? AppColors.textPrimary : AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        children: permissions.map((permission) {
          final isRoleDefault = widget.user.userRole != null &&
              RoleDefinition.getDefaultPermissions(widget.user.userRole!)
                  .contains(permission);
          final isSelected = _selectedPermissions.contains(permission);

          return CheckboxListTile(
            title: Text(
              permission.displayName,
              style: TextStyle(color: enabled ? AppColors.textPrimary : AppColors.textTertiary, fontSize: 13),
            ),
            subtitle: isRoleDefault
                ? const Text(
                    'Inclus dans le rôle',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 11, fontStyle: FontStyle.italic),
                  )
                : null,
            value: isSelected,
            enabled: enabled && !isRoleDefault,
            onChanged: (!enabled || isRoleDefault)
                ? null
                : (value) {
                    setState(() {
                      if (value ?? false) {
                        _selectedPermissions.add(permission);
                      } else {
                        _selectedPermissions.remove(permission);
                      }
                      _hasChanges = true;
                    });
                  },
            secondary: Icon(permission.icon, size: 18, color: enabled ? AppColors.textSecondary : AppColors.textTertiary),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReasonField(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Iconsax.note, color: AppColors.textSecondary, size: 20),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Raison de la modification (optionnel)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Ex: Promotion, changement de fonction...',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> entry) {
    final changeType = entry['changeType'] as String?;
    final timestamp = entry['timestamp'];
    final modifiedByName = entry['modifiedByName'] as String? ?? 'Système';
    final reason = entry['reason'] as String?;

    IconData icon;
    Color color;
    String description;

    switch (changeType) {
      case 'roleChanged':
        icon = Iconsax.user_tag;
        color = AppColors.primary;
        description = 'Rôle: ${entry['previousRole']} → ${entry['newRole']}';
        break;
      case 'permissionsAdded':
        icon = Iconsax.add_circle;
        color = AppColors.success;
        final count = (entry['addedPermissions'] as List?)?.length ?? 0;
        description = '$count permission(s) ajoutée(s)';
        break;
      case 'permissionsRemoved':
        icon = Iconsax.minus_cirlce;
        color = AppColors.error;
        final count = (entry['removedPermissions'] as List?)?.length ?? 0;
        description = '$count permission(s) retirée(s)';
        break;
      default:
        icon = Iconsax.edit;
        color = AppColors.warning;
        description = 'Permissions modifiées';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$modifiedByName • ${_formatTimestamp(timestamp)}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                if (reason != null && reason.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    reason,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: maxLines > 1 ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textTertiary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: maxLines,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActions(AppLocalizations l10n) {
    return Wrap(
      alignment: WrapAlignment.end,
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          ),
          child: Text(l10n.translate('common.cancel'), style: const TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: _hasChanges && !_isLoading ? _handleSave : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.surfaceBorder,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(l10n.translate('common.save'), style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);

    try {
      // Récupérer l'utilisateur connecté depuis le provider
      final currentUser = ref.read(authControllerProvider).value;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Récupérer également l'ID depuis Firebase Auth comme backup
      final firebaseUser = ref.read(currentUserProvider);
      final currentUserId = currentUser.id.isNotEmpty ? currentUser.id : firebaseUser?.uid;

      if (currentUserId == null || currentUserId.isEmpty) {
        throw Exception('ID utilisateur connecté invalide');
      }

      if (widget.user.id.isEmpty) throw Exception('ID utilisateur invalide');

      final repo = ref.read(userManagementRepositoryProvider);
      final currentRole = widget.user.role ?? 'Superviseur Flotte';

      // 1. Upload photo si changée
      String? newPhotoUrl;
      if (_photoChanged) {
        if (_profilePhoto != null) {
          newPhotoUrl = await _imageService.uploadXFile(
            _profilePhoto!,
            'users/${widget.user.id}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
          );
          // Supprimer l'ancienne photo si elle existe
          if (widget.user.photoUrl != null &&
              widget.user.photoUrl!.isNotEmpty) {
            await _imageService.deleteByUrl(widget.user.photoUrl!);
          }
        } else {
          // Photo supprimée
          newPhotoUrl = '';
          if (widget.user.photoUrl != null &&
              widget.user.photoUrl!.isNotEmpty) {
            await _imageService.deleteByUrl(widget.user.photoUrl!);
          }
        }
      }

      // 2. Mettre à jour les infos de base si changées
      if (_firstNameController.text != (widget.user.firstName ?? '') ||
          _lastNameController.text != (widget.user.lastName ?? '') ||
          _phoneController.text != (widget.user.phoneNumber ?? '') ||
          _addressController.text != (widget.user.address ?? '') ||
          _licenseController.text != (widget.user.driverLicenseNumber ?? '') ||
          _selectedDepartment != widget.user.department ||
          _photoChanged) {
        await repo.updateUserBasicInfo(
          userId: widget.user.id,
          firstName: _firstNameController.text.isEmpty ? null : _firstNameController.text,
          lastName: _lastNameController.text.isEmpty ? null : _lastNameController.text,
          phoneNumber: _phoneController.text.isEmpty ? null : _phoneController.text,
          department: _selectedRole == 'Direction' ? _selectedDepartment : null,
          address: _addressController.text.isEmpty ? null : _addressController.text,
          driverLicenseNumber: _licenseController.text.isEmpty ? null : _licenseController.text,
          photoUrl: newPhotoUrl,
        );
      }

      // 2. Mettre à jour le manager si changé
      if (_managerChanged) {
        if (_selectedManagerId != null && _selectedManagerName != null) {
          await repo.assignManager(
            userId: widget.user.id,
            managerId: _selectedManagerId!,
            managerName: _selectedManagerName!,
          );
        } else {
          await repo.removeManager(userId: widget.user.id);
        }
      }

      // 3. Mettre à jour rôle et/ou permissions si changés
      final permissionNames = _selectedPermissions.map((p) => p.name).toList();

      if (_selectedRole != currentRole ||
          !_listsEqual(permissionNames, widget.user.permissions)) {
        await repo.updateUserRoleAndPermissions(
          userId: widget.user.id,
          newRole: _selectedRole,
          additionalPermissions: permissionNames,
          modifiedBy: currentUserId,
          reason: _reasonController.text.isEmpty ? null : _reasonController.text,
        );
      }

      // 4. Rafraîchir les données
      ref.invalidate(allUsersProvider);

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('users.editUserDialog.success')),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.translate('users.editUserDialog.error').replaceAll('{error}', e.toString())),
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

  bool _listsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = a.toSet();
    final bSet = b.toSet();
    return aSet.difference(bSet).isEmpty && bSet.difference(aSet).isEmpty;
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Date inconnue';
    // Firestore Timestamp ou DateTime
    DateTime date;
    if (timestamp is DateTime) {
      date = timestamp;
    } else {
      // C'est un Timestamp Firestore
      date = timestamp.toDate() as DateTime;
    }
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
