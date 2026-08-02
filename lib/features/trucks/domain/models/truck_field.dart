import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Catégories de champs pour organiser la personnalisation
enum TruckFieldCategory {
  identification('Identification Générale'),
  caracteristiquesTechniques('Caractéristiques Techniques'),
  exploitation('Exploitation'),
  maintenance('Maintenance'),
  performance('Performance & Productivité'),
  gps('GPS & Télématique');

  const TruckFieldCategory(this.label);
  final String label;
}

/// Définition d'un champ de camion pour la personnalisation de l'affichage
class TruckField { // Toujours affiché (non désactivable)

  const TruckField({
    required this.key,
    required this.label,
    required this.category,
    required this.icon,
    this.isDefault = false,
    this.isRequired = false,
  });
  final String key;
  final String label;
  final TruckFieldCategory category;
  final IconData icon;
  final bool isDefault; // Affiché par défaut
  final bool isRequired;

  /// Obtenir la valeur du champ depuis un TruckModel
  String getDisplayValue(dynamic truck) {
    // Cette méthode sera implémentée pour extraire la valeur depuis le truck
    return '';
  }
}

/// Liste de tous les champs disponibles pour l'affichage
class TruckFields {
  // ============ IDENTIFICATION GÉNÉRALE ============
  static const immatriculation = TruckField(
    key: 'immatriculation',
    label: 'Immatriculation',
    category: TruckFieldCategory.identification,
    icon: Iconsax.card,
    isRequired: true,
    isDefault: true,
  );

  static const marque = TruckField(
    key: 'marque',
    label: 'Marque',
    category: TruckFieldCategory.identification,
    icon: Iconsax.tag,
    isDefault: true,
  );

  static const modele = TruckField(
    key: 'modele',
    label: 'Modèle',
    category: TruckFieldCategory.identification,
    icon: Iconsax.tag,
    isDefault: true,
  );

  static const numeroInterneFlotte = TruckField(
    key: 'numeroInterneFlotte',
    label: 'N° Flotte',
    category: TruckFieldCategory.identification,
    icon: Iconsax.hashtag,
    isDefault: true,
  );

  static const radarNumber = TruckField(
    key: 'radarNumber',
    label: 'N° Radar',
    category: TruckFieldCategory.identification,
    icon: Iconsax.radar,
  );

  static const proprietaire = TruckField(
    key: 'proprietaire',
    label: 'Propriétaire',
    category: TruckFieldCategory.identification,
    icon: Iconsax.user,
  );

  static const numeroChassis = TruckField(
    key: 'numeroChassis',
    label: 'N° Châssis (VIN)',
    category: TruckFieldCategory.identification,
    icon: Iconsax.scan_barcode,
  );

  static const anneeFabrication = TruckField(
    key: 'anneeFabrication',
    label: 'Année',
    category: TruckFieldCategory.identification,
    icon: Iconsax.calendar,
    isDefault: true,
  );

  static const type = TruckField(
    key: 'type',
    label: 'Type',
    category: TruckFieldCategory.identification,
    icon: Iconsax.truck,
    isDefault: true,
  );

  static const configuration = TruckField(
    key: 'configuration',
    label: 'Configuration',
    category: TruckFieldCategory.identification,
    icon: Iconsax.setting_2,
  );

  static const couleur = TruckField(
    key: 'couleur',
    label: 'Couleur',
    category: TruckFieldCategory.identification,
    icon: Iconsax.brush_1,
  );

  static const assuranceCompagnie = TruckField(
    key: 'assuranceCompagnie',
    label: 'Assurance',
    category: TruckFieldCategory.identification,
    icon: Iconsax.shield_tick,
  );

  static const visiteTechniqueProchaine = TruckField(
    key: 'visiteTechniqueProchaine',
    label: 'Prochaine Visite Technique',
    category: TruckFieldCategory.identification,
    icon: Iconsax.clipboard_tick,
  );

  // ============ CARACTÉRISTIQUES TECHNIQUES ============
  static const typeCarburant = TruckField(
    key: 'typeCarburant',
    label: 'Carburant',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.gas_station,
  );

  static const puissanceCV = TruckField(
    key: 'puissanceCV',
    label: 'Puissance (CV)',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.flash,
  );

  static const capaciteReservoir = TruckField(
    key: 'capaciteReservoir',
    label: 'Capacité Réservoir (L)',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.gas_station,
  );

  static const ptac = TruckField(
    key: 'ptac',
    label: 'PTAC (kg)',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.weight,
  );

  static const chargeUtileMax = TruckField(
    key: 'chargeUtileMax',
    label: 'Charge Utile (t)',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.weight,
    isDefault: true,
  );

  static const boiteVitesses = TruckField(
    key: 'boiteVitesses',
    label: 'Boîte de Vitesses',
    category: TruckFieldCategory.caracteristiquesTechniques,
    icon: Iconsax.setting_2,
  );

  // ============ EXPLOITATION ============
  static const statut = TruckField(
    key: 'statut',
    label: 'Statut',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.status,
    isRequired: true,
    isDefault: true,
  );

  static const siteAffectation = TruckField(
    key: 'siteAffectation',
    label: 'Site',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.location,
    isDefault: true,
  );

  static const zoneExploitation = TruckField(
    key: 'zoneExploitation',
    label: 'Zone',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.map,
  );

  static const typeActivite = TruckField(
    key: 'typeActivite',
    label: 'Activité',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.brifecase_tick,
  );

  static const chauffeurPrincipal = TruckField(
    key: 'chauffeurPrincipal',
    label: 'Chauffeur Principal',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.driver,
    isDefault: true,
  );

  static const kilometrageActuel = TruckField(
    key: 'kilometrageActuel',
    label: 'Kilométrage',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.speedometer,
    isDefault: true,
  );

  static const heuresMoteur = TruckField(
    key: 'heuresMoteur',
    label: 'Heures Moteur',
    category: TruckFieldCategory.exploitation,
    icon: Iconsax.timer_1,
  );

  // ============ MAINTENANCE ============
  static const derniereMaintenanceDate = TruckField(
    key: 'derniereMaintenanceDate',
    label: 'Dernière Maintenance',
    category: TruckFieldCategory.maintenance,
    icon: Iconsax.setting_3,
  );

  static const prochaineMaintenancePrevue = TruckField(
    key: 'prochaineMaintenancePrevue',
    label: 'Prochaine Maintenance',
    category: TruckFieldCategory.maintenance,
    icon: Iconsax.calendar_tick,
    isDefault: true,
  );

  static const planMaintenance = TruckField(
    key: 'planMaintenance',
    label: 'Plan de Maintenance',
    category: TruckFieldCategory.maintenance,
    icon: Iconsax.note,
  );

  static const garagePrestataire = TruckField(
    key: 'garagePrestataire',
    label: 'Garage',
    category: TruckFieldCategory.maintenance,
    icon: Iconsax.building,
  );

  // ============ PERFORMANCE ============
  static const tauxDisponibilite = TruckField(
    key: 'tauxDisponibilite',
    label: 'Disponibilité (%)',
    category: TruckFieldCategory.performance,
    icon: Iconsax.chart_success,
  );

  static const coutParKm = TruckField(
    key: 'coutParKm',
    label: 'Coût/km',
    category: TruckFieldCategory.performance,
    icon: Iconsax.money,
  );

  static const rentabilite = TruckField(
    key: 'rentabilite',
    label: 'Rentabilité',
    category: TruckFieldCategory.performance,
    icon: Iconsax.chart_success,
  );

  static const nombreRotations = TruckField(
    key: 'nombreRotations',
    label: 'Rotations',
    category: TruckFieldCategory.performance,
    icon: Iconsax.repeat,
  );

  static const tonnageTransporte = TruckField(
    key: 'tonnageTransporte',
    label: 'Tonnage Transporté',
    category: TruckFieldCategory.performance,
    icon: Iconsax.weight_1,
  );

  // ============ GPS & TÉLÉMATIQUE ============
  static const identifiantGPS = TruckField(
    key: 'identifiantGPS',
    label: 'ID GPS',
    category: TruckFieldCategory.gps,
    icon: Iconsax.gps,
  );

  static const fournisseurGPS = TruckField(
    key: 'fournisseurGPS',
    label: 'Fournisseur GPS',
    category: TruckFieldCategory.gps,
    icon: Iconsax.building,
  );

  /// Liste de tous les champs disponibles
  static List<TruckField> get allFields => [
        // Identification
        immatriculation,
        marque,
        modele,
        numeroInterneFlotte,
        radarNumber,
        proprietaire,
        numeroChassis,
        anneeFabrication,
        type,
        configuration,
        couleur,
        assuranceCompagnie,
        visiteTechniqueProchaine,
        // Caractéristiques techniques
        typeCarburant,
        puissanceCV,
        capaciteReservoir,
        ptac,
        chargeUtileMax,
        boiteVitesses,
        // Exploitation
        statut,
        siteAffectation,
        zoneExploitation,
        typeActivite,
        chauffeurPrincipal,
        kilometrageActuel,
        heuresMoteur,
        // Maintenance
        derniereMaintenanceDate,
        prochaineMaintenancePrevue,
        planMaintenance,
        garagePrestataire,
        // Performance
        tauxDisponibilite,
        coutParKm,
        rentabilite,
        nombreRotations,
        tonnageTransporte,
        // GPS
        identifiantGPS,
        fournisseurGPS,
      ];

  /// Champs affichés par défaut
  static List<TruckField> get defaultFields =>
      allFields.where((f) => f.isDefault).toList();

  /// Champs requis (toujours affichés)
  static List<TruckField> get requiredFields =>
      allFields.where((f) => f.isRequired).toList();

  /// Champs par catégorie
  static Map<TruckFieldCategory, List<TruckField>> get fieldsByCategory {
    final map = <TruckFieldCategory, List<TruckField>>{};
    for (final category in TruckFieldCategory.values) {
      map[category] = allFields.where((f) => f.category == category).toList();
    }
    return map;
  }
}
