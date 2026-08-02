import 'package:flutter/material.dart';
import '../../../../core/i18n/app_localizations.dart';
import 'role.dart';

/// Helper pour obtenir les noms de rôles traduits
class RoleHelper {
  /// Obtenir le nom traduit d'un rôle
  static String getTranslatedName(BuildContext context, UserRole role) {
    final l10n = AppLocalizations.of(context);

    switch (role) {
      case UserRole.chauffeur:
        return l10n.tr('users.roles.chauffeur');
      case UserRole.superviseurFlotte:
        return l10n.tr('users.roles.superviseurFlotte');
      case UserRole.superviseurGeneral:
        return l10n.tr('users.roles.superviseurGeneral');
      case UserRole.superviseurMine:
        return l10n.tr('users.roles.superviseurMine');
      case UserRole.superviseurPort:
        return l10n.tr('users.roles.superviseurPort');
      case UserRole.superviseurStockage:
        return l10n.tr('users.roles.superviseurStockage');
      case UserRole.rh:
        return l10n.tr('users.roles.rh');
      case UserRole.direction:
        return l10n.tr('users.roles.direction');
      case UserRole.pompiste:
        return l10n.tr('users.roles.pompiste');
      case UserRole.chefRavitaillement:
        return l10n.tr('users.roles.chefRavitaillement');
      case UserRole.responsableApprovisionnement:
        return l10n.tr('users.roles.responsableApprovisionnement');
      case UserRole.responsableOperations:
        return l10n.tr('users.roles.responsableOperations');
      case UserRole.centreTechnique:
        return l10n.tr('users.roles.centreTechnique');
    }
  }

  /// Obtenir le nom traduit à partir d'une chaîne de rôle
  static String getTranslatedNameFromString(BuildContext context, String? roleString) {
    final role = UserRole.fromString(roleString);
    if (role == null) return roleString ?? '';
    return getTranslatedName(context, role);
  }

  /// Obtenir tous les rôles avec leurs noms traduits
  static Map<String, String> getAllRolesTranslated(BuildContext context) {
    return {
      for (final role in UserRole.values)
        role.displayName: getTranslatedName(context, role),
    };
  }

  /// Obtenir une liste des displayNames des rôles (pour les dropdowns)
  static List<String> getRoleDisplayNames() {
    return UserRole.values.map((role) => role.displayName).toList();
  }
}
