import 'permission.dart';

/// Énumération des rôles utilisateurs
enum UserRole {
  chauffeur('Chauffeur', 'CH'),
  rh('RH', 'RH'),
  superviseurFlotte('Superviseur Flotte', 'SFLOT'),
  superviseurGeneral('Superviseur Général', 'SGEN'),
  superviseurMine('Superviseur Mine', 'SMINE'),
  superviseurPort('Superviseur Port', 'SPORT'),
  superviseurStockage('Superviseur Stockage', 'SSTOCK'),
  pompiste('Pompiste', 'POMP'),
  chefRavitaillement('Chef Ravitaillement', 'CRAV'),
  responsableApprovisionnement('Responsable Approvisionnement', 'RAPP'),
  responsableOperations('Responsable Opérations', 'ROP'),
  centreTechnique('Centre Technique', 'CTECH'),
  direction('Direction', 'DIR');

  const UserRole(this.displayName, this.matriculePrefix);

  /// Nom d'affichage du rôle
  final String displayName;

  /// Préfixe du matricule pour ce rôle
  final String matriculePrefix;

  /// Créer un UserRole à partir d'une chaîne
  static UserRole? fromString(String? role) {
    if (role == null) return null;

    final normalized = role.toLowerCase().trim();
    switch (normalized) {
      case 'chauffeur':
      case 'driver':
        return UserRole.chauffeur;
      case 'rh':
      case 'admin':
      case 'administrateur':
        return UserRole.rh;
      case 'responsable flotte':
      case 'responsableflotte':
      case 'responsable':
      case 'manager':
      case 'superviseur flotte':
      case 'superviseurflotte':
        return UserRole.superviseurFlotte;
      case 'superviseur général':
      case 'superviseur general':
      case 'superviseurgeneral':
      case 'superviseur':
      case 'supervisor':
        return UserRole.superviseurGeneral;
      case 'superviseur mine':
      case 'superviseurmine':
      case 'pointeur mine':
        return UserRole.superviseurMine;
      case 'superviseur port':
      case 'superviseurport':
      case 'pointeur port':
        return UserRole.superviseurPort;
      case 'superviseur stockage':
      case 'superviseurstockage':
      case 'pointeur stockage':
        return UserRole.superviseurStockage;
      case 'direction':
      case 'management':
        return UserRole.direction;
      case 'pompiste':
      case 'fuel attendant':
        return UserRole.pompiste;
      case 'chef ravitaillement':
      case 'chefravitaillement':
        return UserRole.chefRavitaillement;
      case 'responsable approvisionnement':
      case 'responsableapprovisionnement':
        return UserRole.responsableApprovisionnement;
      case 'responsable opérations':
      case 'responsable operations':
      case 'responsableoperations':
        return UserRole.responsableOperations;
      case 'centre technique':
      case 'centretechnique':
        return UserRole.centreTechnique;
      default:
        return null;
    }
  }
}

/// Définition des permissions par défaut pour chaque rôle
class RoleDefinition {
  /// Obtenir les permissions par défaut d'un rôle
  static Set<Permission> getDefaultPermissions(UserRole role) {
    switch (role) {
      case UserRole.chauffeur:
        return {
          Permission.viewVehicles,
          Permission.viewFleets,
          Permission.viewDrivers,
          Permission.startShift,
          Permission.endShift,
          Permission.reportBreakdown,
          Permission.viewTrips,
        };

      case UserRole.rh:
        return {
          Permission.viewVehicles,
          Permission.viewFleets,
          Permission.viewUsers,
          Permission.createUsers,
          Permission.editUsers,
          Permission.deleteUsers,
          Permission.managePermissions,
          Permission.viewAuditLogs,
        };

      case UserRole.superviseurFlotte:
        return {
          Permission.viewVehicles,
          Permission.createVehicles,
          Permission.editVehicles,
          Permission.viewFleets,
          Permission.createFleets,
          Permission.editFleets,
          Permission.viewDrivers,
          Permission.assignDrivers,
          Permission.viewGpsTracking,
          Permission.viewReports,
          Permission.inspectVehicle,
          Permission.validateVehicleState,
          Permission.manageShifts,
          Permission.createFuelRequest,
          Permission.viewFuelRequests,
          Permission.validateTrip,
          Permission.viewTrips,
          Permission.viewWeighings,
          Permission.viewBreakdowns,
        };

      case UserRole.superviseurGeneral:
        return {
          Permission.viewVehicles,
          Permission.createVehicles,
          Permission.editVehicles,
          Permission.viewFleets,
          Permission.createFleets,
          Permission.editFleets,
          Permission.viewDrivers,
          Permission.assignDrivers,
          Permission.viewGpsTracking,
          Permission.viewReports,
          Permission.exportData,
          Permission.inspectVehicle,
          Permission.validateVehicleState,
          Permission.manageShifts,
          Permission.createFuelRequest,
          Permission.viewFuelRequests,
          Permission.validateTrip,
          Permission.viewTrips,
          Permission.viewWeighings,
          Permission.viewBreakdowns,
        };

      case UserRole.superviseurMine:
        return {
          Permission.viewVehicles,
          Permission.recordWeighing,
          Permission.viewWeighings,
        };

      case UserRole.superviseurPort:
        return {
          Permission.viewVehicles,
          Permission.recordWeighing,
          Permission.viewWeighings,
        };

      case UserRole.superviseurStockage:
        return {
          Permission.viewVehicles,
          Permission.recordWeighing,
          Permission.viewWeighings,
        };

      case UserRole.pompiste:
        return {
          Permission.addFuel,
          Permission.serveFuel,
          Permission.viewFuelRequests,
        };

      case UserRole.chefRavitaillement:
        return {
          Permission.viewFuelRequests,
          Permission.validateFuelRequest,
          Permission.viewReports,
          Permission.addFuel,
          Permission.serveFuel,
        };

      case UserRole.responsableApprovisionnement:
        return {
          Permission.viewFuelRequests,
          Permission.validateFuelRequest,
          Permission.viewReports,
          Permission.exportData,
        };

      case UserRole.responsableOperations:
        return {
          Permission.viewVehicles,
          Permission.viewDrivers,
          Permission.viewTrips,
          Permission.viewWeighings,
          Permission.viewBreakdowns,
          Permission.viewReports,
          Permission.exportData,
          Permission.viewFuelRequests,
        };

      case UserRole.centreTechnique:
        return {
          Permission.viewVehicles,
          Permission.manageDiagnostic,
          Permission.viewBreakdowns,
        };

      case UserRole.direction:
        return {Permission.fullAccess};
    }
  }

  /// Obtenir la description d'un rôle
  static String getDescription(UserRole role) {
    switch (role) {
      case UserRole.chauffeur:
        return 'Conduite des véhicules, prise de fonction, signalement de pannes';
      case UserRole.rh:
        return 'Gestion complète des utilisateurs, lecture des véhicules/flottes';
      case UserRole.superviseurFlotte:
        return 'Inspection véhicules, affectation chauffeurs, demandes carburant, validation rotations';
      case UserRole.superviseurGeneral:
        return 'Supervision générale de toutes les flottes et opérations';
      case UserRole.superviseurMine:
        return 'Pointage et pesée des camions à la mine';
      case UserRole.superviseurPort:
        return 'Pointage et pesée des camions au port';
      case UserRole.superviseurStockage:
        return 'Gestion des déchargements et chargements au point de stockage';
      case UserRole.direction:
        return 'Accès complet à toutes les fonctionnalités';
      case UserRole.pompiste:
        return 'Ravitaillement en carburant des véhicules';
      case UserRole.chefRavitaillement:
        return 'Supervision des opérations de ravitaillement en carburant';
      case UserRole.responsableApprovisionnement:
        return 'Gestion de la chaîne d\'approvisionnement en carburant';
      case UserRole.responsableOperations:
        return 'Supervision des opérations de transport et logistique';
      case UserRole.centreTechnique:
        return 'Diagnostic et réparation des véhicules en panne';
    }
  }

  /// Vérifier si un rôle peut gérer les permissions
  static bool canManagePermissions(UserRole role) {
    return role == UserRole.rh || role == UserRole.direction;
  }

  /// Vérifier si un rôle peut gérer les véhicules
  static bool canManageVehicles(UserRole role) {
    return role == UserRole.superviseurFlotte ||
        role == UserRole.superviseurGeneral ||
        role == UserRole.direction;
  }

  /// Vérifier si un rôle peut gérer les utilisateurs
  static bool canManageUsers(UserRole role) {
    return role == UserRole.rh || role == UserRole.direction;
  }

  /// Obtenir tous les rôles disponibles
  static List<UserRole> get allRoles => UserRole.values;

  /// Obtenir les rôles qui peuvent créer des utilisateurs
  static List<UserRole> get rolesCanCreateUsers => [
        UserRole.rh,
        UserRole.direction,
      ];
}
