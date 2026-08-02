import '../../domain/models/permission.dart';
import '../../domain/models/role.dart';
import '../../domain/models/user_model.dart';

/// Service centralisé pour la vérification des permissions
class PermissionService {
  /// Vérifier si un utilisateur a une permission spécifique
  bool can(UserModel user, Permission permission) {
    return user.hasPermission(permission);
  }

  /// Vérifier si un utilisateur a toutes les permissions spécifiées (AND)
  bool canAll(UserModel user, List<Permission> permissions) {
    return permissions.every((p) => can(user, p));
  }

  /// Vérifier si un utilisateur a au moins une des permissions spécifiées (OR)
  bool canAny(UserModel user, List<Permission> permissions) {
    return permissions.any((p) => can(user, p));
  }

  /// Obtenir toutes les permissions effectives d'un utilisateur
  Set<Permission> getEffectivePermissions(UserModel user) {
    return user.effectivePermissions;
  }

  /// Obtenir les permissions par défaut d'un rôle
  Set<Permission> getRoleDefaultPermissions(UserRole role) {
    return RoleDefinition.getDefaultPermissions(role);
  }

  /// Obtenir les permissions groupées par catégorie
  Map<PermissionCategory, List<Permission>> getPermissionsByCategory(
      UserModel user) {
    final effectivePerms = user.effectivePermissions;
    final grouped = <PermissionCategory, List<Permission>>{};

    for (final category in PermissionCategory.values) {
      grouped[category] = Permission.values
          .where((perm) =>
              perm.category == category && effectivePerms.contains(perm))
          .toList();
    }

    return grouped;
  }

  /// Obtenir toutes les permissions disponibles groupées par catégorie
  Map<PermissionCategory, List<Permission>> getAllPermissionsByCategory() {
    final grouped = <PermissionCategory, List<Permission>>{};

    for (final category in PermissionCategory.values) {
      grouped[category] = Permission.values
          .where((perm) => perm.category == category)
          .toList();
    }

    return grouped;
  }

  /// Vérifier si un utilisateur peut gérer les permissions
  bool canManagePermissions(UserModel user) {
    return user.hasPermission(Permission.managePermissions);
  }

  /// Vérifier si un utilisateur peut gérer les utilisateurs
  bool canManageUsers(UserModel user) {
    return user.hasAnyPermission([
      Permission.createUsers,
      Permission.editUsers,
      Permission.deleteUsers,
    ]);
  }

  /// Vérifier si un utilisateur peut gérer les véhicules
  bool canManageVehicles(UserModel user) {
    return user.hasAnyPermission([
      Permission.createVehicles,
      Permission.editVehicles,
      Permission.deleteVehicles,
    ]);
  }

  /// Vérifier si un utilisateur peut gérer les flottes
  bool canManageFleets(UserModel user) {
    return user.hasAnyPermission([
      Permission.createFleets,
      Permission.editFleets,
      Permission.deleteFleets,
    ]);
  }

  /// Vérifier si un utilisateur a accès complet
  bool hasFullAccess(UserModel user) {
    return user.hasPermission(Permission.fullAccess);
  }

  /// Comparer les permissions de deux utilisateurs
  bool hasSamePermissions(UserModel user1, UserModel user2) {
    final perms1 = user1.effectivePermissions;
    final perms2 = user2.effectivePermissions;

    return perms1.length == perms2.length &&
        perms1.every(perms2.contains);
  }

  /// Obtenir les permissions additionnelles (au-delà du rôle)
  Set<Permission> getAdditionalPermissions(UserModel user) {
    if (user.userRole == null) return {};

    final rolePerms = RoleDefinition.getDefaultPermissions(user.userRole!);
    final allPerms = user.effectivePermissions;

    return allPerms.difference(rolePerms);
  }

  /// Vérifier si un utilisateur a des permissions supplémentaires
  bool hasAdditionalPermissions(UserModel user) {
    return getAdditionalPermissions(user).isNotEmpty;
  }
}
