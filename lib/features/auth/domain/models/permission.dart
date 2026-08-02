import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Énumération de toutes les permissions granulaires de l'application
enum Permission {
  // Permissions Véhicules
  viewVehicles,
  createVehicles,
  editVehicles,
  deleteVehicles,

  // Permissions Flottes
  viewFleets,
  createFleets,
  editFleets,
  deleteFleets,

  // Permissions Gestion Utilisateurs
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,
  managePermissions,

  // Permissions Chauffeurs & GPS
  viewDrivers,
  assignDrivers,
  viewGpsTracking,

  // Permissions Administration
  viewReports,
  exportData,
  manageSettings,
  viewAuditLogs,
  fullAccess,

  // Permissions Carburant
  addFuel,
  serveFuel,
  createFuelRequest,
  viewFuelRequests,
  validateFuelRequest,

  // Permissions Inspection
  inspectVehicle,
  validateVehicleState,

  // Permissions Vacations (Shifts)
  startShift,
  endShift,
  manageShifts,

  // Permissions Pesée
  recordWeighing,
  viewWeighings,

  // Permissions Rotations (Trips)
  validateTrip,
  viewTrips,

  // Permissions Pannes
  reportBreakdown,
  manageDiagnostic,
  viewBreakdowns,
}

/// Catégories de permissions pour organisation UI
enum PermissionCategory {
  vehicles,
  fleets,
  users,
  drivers,
  gps,
  administration,
  fuel,
  inspection,
  shifts,
  weighing,
  trips,
  breakdowns,
}

/// Extension pour ajouter des métadonnées aux permissions
extension PermissionExtension on Permission {
  /// Nom d'affichage en français
  String get displayName {
    switch (this) {
      // Véhicules
      case Permission.viewVehicles:
        return 'Voir les véhicules';
      case Permission.createVehicles:
        return 'Créer des véhicules';
      case Permission.editVehicles:
        return 'Modifier des véhicules';
      case Permission.deleteVehicles:
        return 'Supprimer des véhicules';

      // Flottes
      case Permission.viewFleets:
        return 'Voir les flottes';
      case Permission.createFleets:
        return 'Créer des flottes';
      case Permission.editFleets:
        return 'Modifier des flottes';
      case Permission.deleteFleets:
        return 'Supprimer des flottes';

      // Utilisateurs
      case Permission.viewUsers:
        return 'Voir les utilisateurs';
      case Permission.createUsers:
        return 'Créer des utilisateurs';
      case Permission.editUsers:
        return 'Modifier des utilisateurs';
      case Permission.deleteUsers:
        return 'Supprimer des utilisateurs';
      case Permission.managePermissions:
        return 'Gérer les permissions';

      // Chauffeurs & GPS
      case Permission.viewDrivers:
        return 'Voir les chauffeurs';
      case Permission.assignDrivers:
        return 'Assigner des chauffeurs';
      case Permission.viewGpsTracking:
        return 'Voir le suivi GPS';

      // Administration
      case Permission.viewReports:
        return 'Voir les rapports';
      case Permission.exportData:
        return 'Exporter des données';
      case Permission.manageSettings:
        return 'Gérer les paramètres';
      case Permission.viewAuditLogs:
        return "Voir l'historique d'audit";
      case Permission.fullAccess:
        return 'Accès complet';

      // Carburant
      case Permission.addFuel:
        return 'Ajouter du carburant';
      case Permission.serveFuel:
        return 'Servir du carburant';
      case Permission.createFuelRequest:
        return 'Créer une demande de carburant';
      case Permission.viewFuelRequests:
        return 'Voir les demandes de carburant';
      case Permission.validateFuelRequest:
        return 'Valider les demandes de carburant';

      // Inspection
      case Permission.inspectVehicle:
        return 'Inspecter un véhicule';
      case Permission.validateVehicleState:
        return "Valider l'état d'un véhicule";

      // Vacations
      case Permission.startShift:
        return 'Démarrer une vacation';
      case Permission.endShift:
        return 'Terminer une vacation';
      case Permission.manageShifts:
        return 'Gérer les vacations';

      // Pesée
      case Permission.recordWeighing:
        return 'Enregistrer une pesée';
      case Permission.viewWeighings:
        return 'Voir les pesées';

      // Rotations
      case Permission.validateTrip:
        return 'Valider une rotation';
      case Permission.viewTrips:
        return 'Voir les rotations';

      // Pannes
      case Permission.reportBreakdown:
        return 'Signaler une panne';
      case Permission.manageDiagnostic:
        return 'Gérer les diagnostics';
      case Permission.viewBreakdowns:
        return 'Voir les pannes';
    }
  }

  /// Catégorie de la permission
  PermissionCategory get category {
    switch (this) {
      case Permission.viewVehicles:
      case Permission.createVehicles:
      case Permission.editVehicles:
      case Permission.deleteVehicles:
        return PermissionCategory.vehicles;

      case Permission.viewFleets:
      case Permission.createFleets:
      case Permission.editFleets:
      case Permission.deleteFleets:
        return PermissionCategory.fleets;

      case Permission.viewUsers:
      case Permission.createUsers:
      case Permission.editUsers:
      case Permission.deleteUsers:
      case Permission.managePermissions:
        return PermissionCategory.users;

      case Permission.viewDrivers:
      case Permission.assignDrivers:
        return PermissionCategory.drivers;

      case Permission.viewGpsTracking:
        return PermissionCategory.gps;

      case Permission.viewReports:
      case Permission.exportData:
      case Permission.manageSettings:
      case Permission.viewAuditLogs:
      case Permission.fullAccess:
        return PermissionCategory.administration;

      case Permission.addFuel:
      case Permission.serveFuel:
      case Permission.createFuelRequest:
      case Permission.viewFuelRequests:
      case Permission.validateFuelRequest:
        return PermissionCategory.fuel;

      case Permission.inspectVehicle:
      case Permission.validateVehicleState:
        return PermissionCategory.inspection;

      case Permission.startShift:
      case Permission.endShift:
      case Permission.manageShifts:
        return PermissionCategory.shifts;

      case Permission.recordWeighing:
      case Permission.viewWeighings:
        return PermissionCategory.weighing;

      case Permission.validateTrip:
      case Permission.viewTrips:
        return PermissionCategory.trips;

      case Permission.reportBreakdown:
      case Permission.manageDiagnostic:
      case Permission.viewBreakdowns:
        return PermissionCategory.breakdowns;
    }
  }

  /// Icône associée à la permission
  IconData get icon {
    switch (this) {
      // Véhicules
      case Permission.viewVehicles:
        return Iconsax.truck;
      case Permission.createVehicles:
        return Iconsax.add_circle;
      case Permission.editVehicles:
        return Iconsax.edit;
      case Permission.deleteVehicles:
        return Iconsax.trash;

      // Flottes
      case Permission.viewFleets:
        return Iconsax.category;
      case Permission.createFleets:
        return Iconsax.add_square;
      case Permission.editFleets:
        return Iconsax.edit_2;
      case Permission.deleteFleets:
        return Iconsax.close_square;

      // Utilisateurs
      case Permission.viewUsers:
        return Iconsax.people;
      case Permission.createUsers:
        return Iconsax.user_add;
      case Permission.editUsers:
        return Iconsax.user_edit;
      case Permission.deleteUsers:
        return Iconsax.user_remove;
      case Permission.managePermissions:
        return Iconsax.shield_tick;

      // Chauffeurs & GPS
      case Permission.viewDrivers:
        return Iconsax.driver;
      case Permission.assignDrivers:
        return Iconsax.user_tag;
      case Permission.viewGpsTracking:
        return Iconsax.location;

      // Administration
      case Permission.viewReports:
        return Iconsax.document_text;
      case Permission.exportData:
        return Iconsax.export_1;
      case Permission.manageSettings:
        return Iconsax.setting_2;
      case Permission.viewAuditLogs:
        return Iconsax.note;
      case Permission.fullAccess:
        return Iconsax.star;

      // Carburant
      case Permission.addFuel:
        return Iconsax.gas_station;
      case Permission.serveFuel:
        return Iconsax.gas_station;
      case Permission.createFuelRequest:
        return Iconsax.document_upload;
      case Permission.viewFuelRequests:
        return Iconsax.document_text_1;
      case Permission.validateFuelRequest:
        return Iconsax.tick_square;

      // Inspection
      case Permission.inspectVehicle:
        return Iconsax.search_status;
      case Permission.validateVehicleState:
        return Iconsax.shield_search;

      // Vacations
      case Permission.startShift:
        return Iconsax.play_circle;
      case Permission.endShift:
        return Iconsax.stop_circle;
      case Permission.manageShifts:
        return Iconsax.calendar;

      // Pesée
      case Permission.recordWeighing:
        return Iconsax.weight;
      case Permission.viewWeighings:
        return Iconsax.chart_2;

      // Rotations
      case Permission.validateTrip:
        return Iconsax.tick_circle;
      case Permission.viewTrips:
        return Iconsax.routing;

      // Pannes
      case Permission.reportBreakdown:
        return Iconsax.warning_2;
      case Permission.manageDiagnostic:
        return Iconsax.cpu_setting;
      case Permission.viewBreakdowns:
        return Iconsax.danger;
    }
  }

  /// Description de la permission
  String get description {
    switch (this) {
      case Permission.viewVehicles:
        return 'Permet de consulter la liste des véhicules';
      case Permission.createVehicles:
        return 'Permet d\'ajouter de nouveaux véhicules';
      case Permission.editVehicles:
        return 'Permet de modifier les informations des véhicules';
      case Permission.deleteVehicles:
        return 'Permet de supprimer des véhicules';
      case Permission.viewFleets:
        return 'Permet de consulter les flottes';
      case Permission.createFleets:
        return 'Permet de créer de nouvelles flottes';
      case Permission.editFleets:
        return 'Permet de modifier les flottes existantes';
      case Permission.deleteFleets:
        return 'Permet de supprimer des flottes';
      case Permission.viewUsers:
        return 'Permet de voir la liste des utilisateurs';
      case Permission.createUsers:
        return 'Permet de créer de nouveaux utilisateurs';
      case Permission.editUsers:
        return 'Permet de modifier les utilisateurs';
      case Permission.deleteUsers:
        return 'Permet de supprimer des utilisateurs';
      case Permission.managePermissions:
        return 'Permet de gérer les rôles et permissions';
      case Permission.viewDrivers:
        return 'Permet de consulter la liste des chauffeurs';
      case Permission.assignDrivers:
        return 'Permet d\'assigner des chauffeurs aux véhicules';
      case Permission.viewGpsTracking:
        return 'Permet de consulter le suivi GPS en temps réel';
      case Permission.viewReports:
        return 'Permet de consulter les rapports';
      case Permission.exportData:
        return 'Permet d\'exporter les données';
      case Permission.manageSettings:
        return 'Permet de gérer les paramètres de l\'application';
      case Permission.viewAuditLogs:
        return 'Permet de consulter l\'historique des modifications';
      case Permission.fullAccess:
        return 'Donne un accès complet à toute l\'application';
      case Permission.addFuel:
        return 'Permet d\'ajouter du carburant aux véhicules';
      case Permission.serveFuel:
        return 'Permet de servir du carburant à un véhicule';
      case Permission.createFuelRequest:
        return 'Permet de créer une demande de ravitaillement';
      case Permission.viewFuelRequests:
        return 'Permet de consulter les demandes de carburant';
      case Permission.validateFuelRequest:
        return 'Permet de valider les demandes de carburant';
      case Permission.inspectVehicle:
        return 'Permet d\'inspecter l\'état d\'un véhicule';
      case Permission.validateVehicleState:
        return 'Permet de valider l\'état général d\'un véhicule';
      case Permission.startShift:
        return 'Permet de démarrer une prise de fonction';
      case Permission.endShift:
        return 'Permet de terminer une vacation';
      case Permission.manageShifts:
        return 'Permet de gérer les vacations et affectations';
      case Permission.recordWeighing:
        return 'Permet d\'enregistrer une pesée sur le pont bascule';
      case Permission.viewWeighings:
        return 'Permet de consulter l\'historique des pesées';
      case Permission.validateTrip:
        return 'Permet de valider une rotation complète';
      case Permission.viewTrips:
        return 'Permet de consulter les rotations';
      case Permission.reportBreakdown:
        return 'Permet de signaler une panne de véhicule';
      case Permission.manageDiagnostic:
        return 'Permet de gérer les diagnostics et réparations';
      case Permission.viewBreakdowns:
        return 'Permet de consulter les pannes signalées';
    }
  }
}

/// Extension pour les catégories de permissions
extension PermissionCategoryExtension on PermissionCategory {
  /// Nom d'affichage de la catégorie
  String get displayName {
    switch (this) {
      case PermissionCategory.vehicles:
        return 'Véhicules';
      case PermissionCategory.fleets:
        return 'Flottes';
      case PermissionCategory.users:
        return 'Utilisateurs';
      case PermissionCategory.drivers:
        return 'Chauffeurs';
      case PermissionCategory.gps:
        return 'Suivi GPS';
      case PermissionCategory.administration:
        return 'Administration';
      case PermissionCategory.fuel:
        return 'Carburant';
      case PermissionCategory.inspection:
        return 'Inspection';
      case PermissionCategory.shifts:
        return 'Vacations';
      case PermissionCategory.weighing:
        return 'Pesée';
      case PermissionCategory.trips:
        return 'Rotations';
      case PermissionCategory.breakdowns:
        return 'Pannes';
    }
  }

  /// Icône de la catégorie
  IconData get icon {
    switch (this) {
      case PermissionCategory.vehicles:
        return Iconsax.truck_fast;
      case PermissionCategory.fleets:
        return Iconsax.category;
      case PermissionCategory.users:
        return Iconsax.people;
      case PermissionCategory.drivers:
        return Iconsax.driver;
      case PermissionCategory.gps:
        return Iconsax.gps;
      case PermissionCategory.administration:
        return Iconsax.setting_2;
      case PermissionCategory.fuel:
        return Iconsax.gas_station;
      case PermissionCategory.inspection:
        return Iconsax.search_status;
      case PermissionCategory.shifts:
        return Iconsax.calendar;
      case PermissionCategory.weighing:
        return Iconsax.weight;
      case PermissionCategory.trips:
        return Iconsax.routing;
      case PermissionCategory.breakdowns:
        return Iconsax.warning_2;
    }
  }

  /// Couleur associée à la catégorie
  Color get color {
    switch (this) {
      case PermissionCategory.vehicles:
        return const Color(0xFF2196F3); // Bleu
      case PermissionCategory.fleets:
        return const Color(0xFF9C27B0); // Violet
      case PermissionCategory.users:
        return const Color(0xFF4CAF50); // Vert
      case PermissionCategory.drivers:
        return const Color(0xFFFF9800); // Orange
      case PermissionCategory.gps:
        return const Color(0xFFF44336); // Rouge
      case PermissionCategory.administration:
        return const Color(0xFF607D8B); // Gris bleu
      case PermissionCategory.fuel:
        return const Color(0xFFE91E63); // Rose
      case PermissionCategory.inspection:
        return const Color(0xFF00BCD4); // Cyan
      case PermissionCategory.shifts:
        return const Color(0xFF795548); // Marron
      case PermissionCategory.weighing:
        return const Color(0xFF3F51B5); // Indigo
      case PermissionCategory.trips:
        return const Color(0xFF009688); // Teal
      case PermissionCategory.breakdowns:
        return const Color(0xFFFF5722); // Orange foncé
    }
  }
}
