import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/inline_error_retry.dart';
import '../../../auth/domain/models/user_model.dart';
import '../providers/user_management_providers.dart';
import '../widgets/create_user_dialog.dart';
import '../widgets/edit_user_dialog.dart';

/// Écran de gestion des utilisateurs - Réservé au rôle RH
class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterRole = 'Tous';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showCreateUserDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => const CreateUserDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final statsAsync = ref.watch(userStatsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildHeader(statsAsync),
          _buildSearchBar(),
          Expanded(
            child: usersAsync.when(
              data: _buildUsersList,
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, stack) => Center(
                child: Text(
                  'Erreur: $error',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<Map<String, int>> statsAsync) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.backgroundSecondary, AppColors.surface],
        ),
        border: Border(
          bottom: BorderSide(color: AppColors.surfaceBorder),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.glow,
                ),
                child: const Icon(
                  Iconsax.people,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.translate('users.title'),
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.translate('users.subtitle'),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ],
                ),
              ),
              _buildCreateButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          statsAsync.when(
            data: _buildStatsCards,
            loading: () => const SizedBox.shrink(),
            error: (_, __) => InlineErrorRetry(
              onRetry: () => ref.invalidate(userStatsProvider),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Map<String, int> stats) {
    final l10n = AppLocalizations.of(context);
    final totalUsers = stats.values.fold<int>(0, (sum, count) => sum + count);
    final chauffeurs = stats['Chauffeur'] ?? 0;
    final responsables = stats['Responsable'] ?? 0;
    final superviseurs = stats['Superviseur'] ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                l10n.translate('users.total'),
                totalUsers.toString(),
                Iconsax.people,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                l10n.translate('users.drivers'),
                chauffeurs.toString(),
                Iconsax.driver,
                AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                l10n.translate('users.managers'),
                responsables.toString(),
                Iconsax.user_octagon,
                AppColors.warning,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _buildStatCard(
                l10n.translate('users.supervisors'),
                superviseurs.toString(),
                Iconsax.shield_tick,
                AppColors.info,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final l10n = AppLocalizations.of(context);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _showCreateUserDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: AppShadows.glow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Iconsax.add_circle, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.translate('users.createUser'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final l10n = AppLocalizations.of(context);

    final searchField = Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) => setState(() => _searchQuery = value),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        decoration: InputDecoration(
          hintText: l10n.translate('users.searchPlaceholder'),
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 14),
          prefixIcon: const Icon(Iconsax.search_normal_1, color: AppColors.textTertiary, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );

    final roleDropdown = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: DropdownButton<String>(
        value: _filterRole,
        underline: const SizedBox.shrink(),
        dropdownColor: AppColors.surface,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
        icon: const Icon(Iconsax.arrow_down_1, color: AppColors.textTertiary, size: 16),
        isExpanded: context.isMobile,
        items: [
          'Tous',
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
                  child: Text(_translateRoleFilter(role, l10n)),
                ))
            .toList(),
        onChanged: (value) => setState(() => _filterRole = value ?? 'Tous'),
      ),
    );

    final inner = context.isMobile
        ? Column(
            children: [
              searchField,
              const SizedBox(height: AppSpacing.sm),
              roleDropdown,
            ],
          )
        : Row(
            children: [
              Expanded(flex: 2, child: searchField),
              const SizedBox(width: AppSpacing.sm),
              roleDropdown,
            ],
          );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: context.responsiveHorizontalPadding,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: inner,
    );
  }

  Widget _buildUsersList(List<UserModel> users) {
    // Les chauffeurs sont gérés depuis l'écran Chauffeurs — exclure ici
    var filteredUsers = users.where((u) => u.role?.toLowerCase() != 'chauffeur').toList();

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filteredUsers = users.where((user) {
        return user.fullName.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.matricule?.toLowerCase().contains(query) ?? false) ||
            (user.phoneNumber?.contains(query) ?? false);
      }).toList();
    }

    if (_filterRole != 'Tous') {
      filteredUsers = filteredUsers.where((user) => user.role == _filterRole).toList();
    }

    if (filteredUsers.isEmpty) {
      final l10n = AppLocalizations.of(context);
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.search_normal,
              size: 64,
              color: AppColors.textTertiary.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.translate('users.noUsersFound'),
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        return _buildUserCard(user, index);
      },
    );
  }

  Widget _buildUserCard(UserModel user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: _buildUserAvatar(user),
        title: Row(
          children: [
            Flexible(
              child: Text(
                user.fullName.isEmpty ? user.email : user.fullName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (!user.isActive) ...[
              const SizedBox(width: AppSpacing.sm),
              _buildInactiveBadge(),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                _buildInfoChip(user.matricule ?? 'N/A', Iconsax.card),
                _buildInfoChip(user.role ?? 'N/A', Iconsax.user_tag),
                if (user.phoneNumber != null)
                  _buildInfoChip(user.phoneNumber!, Iconsax.call),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Créé le ${DateFormat('dd/MM/yyyy').format(user.createdAt)}',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Iconsax.edit, color: AppColors.info),
              onPressed: () => _showEditUserDialog(user),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: Icon(
                user.isActive ? Iconsax.user_remove : Iconsax.user_tick,
                color: user.isActive ? AppColors.warning : AppColors.success,
              ),
              onPressed: () => _toggleUserStatus(user),
              tooltip: user.isActive ? 'Désactiver' : 'Activer',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel user) {
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;
    if (hasPhoto) {
      return ClipOval(
        child: Image.network(
          user.photoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildInitialsAvatar(user),
        ),
      );
    }
    return _buildInitialsAvatar(user);
  }

  Widget _buildInitialsAvatar(UserModel user) {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInactiveBadge() {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        l10n.translate('users.inactive'),
        style: const TextStyle(
          color: AppColors.error,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showEditUserDialog(UserModel user) {
    showDialog<void>(
      context: context,
      builder: (context) => EditUserDialog(user: user),
    ).then((_) {
      // Rafraîchir la liste après modification
      ref.invalidate(allUsersProvider);
    });
  }

  Future<void> _toggleUserStatus(UserModel user) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          user.isActive ? l10n.translate('users.deactivateUser') : l10n.translate('users.activateUser'),
          style: const TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          user.isActive
              ? l10n.translate('users.confirmDeactivate').replaceAll('{name}', user.fullName)
              : l10n.translate('users.confirmActivate').replaceAll('{name}', user.fullName),
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              user.isActive ? l10n.translate('users.deactivate') : l10n.translate('users.activate'),
              style: TextStyle(
                color: user.isActive ? AppColors.error : AppColors.success,
              ),
            ),
          ),
        ],
      ),
    );

    if ((confirmed ?? false) && mounted) {
      try {
        if (user.isActive) {
          await ref.read(userManagementRepositoryProvider).deactivateUser(user.id);
        } else {
          await ref.read(userManagementRepositoryProvider).activateUser(user.id);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                user.isActive
                    ? l10n.translate('users.userDeactivated')
                    : l10n.translate('users.userActivated'),
              ),
              backgroundColor: AppColors.success,
            ),
          );
        }

        ref.invalidate(allUsersProvider);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.commonError}: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }

  String _translateRoleFilter(String role, AppLocalizations l10n) {
    switch (role) {
      case 'Tous':
        return l10n.translate('users.filterAll');
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
}
