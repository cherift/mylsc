import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de camion
enum TruckType {
  porteur('Porteur'),
  tracteurRoutier('Tracteur routier'),
  benne('Benne'),
  plateau('Plateau'),
  citerne('Citerne'),
  frigorifique('Frigorifique');

  const TruckType(this.label);
  final String label;
}

/// Configuration du camion (essieux)
enum TruckConfiguration {
  config4x2('4x2'),
  config6x4('6x4'),
  config8x4('8x4');

  const TruckConfiguration(this.label);
  final String label;
}

/// Statut opérationnel du camion
enum TruckStatus {
  enService('En service'),
  enMaintenance('En maintenance'),
  enPanne('En panne'),
  immobilise('Immobilisé');

  const TruckStatus(this.label);
  final String label;
}

/// Type de carburant
enum FuelType {
  diesel('Diesel'),
  essence('Essence'),
  gaz('Gaz'),
  electrique('Électrique'),
  hybride('Hybride');

  const FuelType(this.label);
  final String label;
}

/// Type de boîte de vitesses
enum GearboxType {
  manuelle('Manuelle'),
  automatique('Automatique'),
  robotisee('Robotisée');

  const GearboxType(this.label);
  final String label;
}

/// Type d'activité
enum ActivityType {
  mine('Mine'),
  chantier('Chantier'),
  port('Port'),
  longCourrier('Long courrier');

  const ActivityType(this.label);
  final String label;
}

/// Plan de maintenance
enum MaintenancePlan {
  parKilometrage('Par kilométrage'),
  parHeuresMoteur('Par heures moteur'),
  mixte('Mixte');

  const MaintenancePlan(this.label);
  final String label;
}

/// Modèle complet d'un camion
class TruckModel {

  TruckModel({
    required this.id,
    required this.proprietaire,
    required this.numeroInterneFlotte,
    required this.immatriculation,
    required this.numeroChassis,
    required this.marque,
    required this.modele,
    required this.anneeFabrication,
    required this.dateEntreeFlotte, required this.type, required this.configuration, required this.statut, required this.kilometrageInitial, required this.kilometrageActuel, required this.createdAt, this.numeroCarteGrise,
    this.dateMiseEnCirculation,
    this.assuranceCompagnie,
    this.assuranceNumeroPolice,
    this.assuranceDateDebut,
    this.assuranceDateFin,
    this.visiteTechniqueDerniere,
    this.visiteTechniqueProchaine,
    this.paysOrigine,
    this.couleur,
    this.numeroMoteur,
    this.normeMoteur,
    this.typeMoteur,
    this.puissanceCV,
    this.puissanceKW,
    this.cylindree,
    this.typeCarburant,
    this.capaciteReservoir,
    this.boiteVitesses,
    this.nombreRapports,
    this.typeEmbrayage,
    this.poidsAVide,
    this.ptac,
    this.ptra,
    this.chargeUtileMax,
    this.volumeUtile,
    this.longueur,
    this.largeur,
    this.hauteur,
    this.siteAffectation,
    this.zoneExploitation,
    this.typeActivite,
    this.chauffeurPrincipalId,
    this.chauffeurSecondaireId,
    this.fleetId,
    this.responsableFlotteId,
    this.heuresMoteur,
    this.planMaintenance,
    this.frequenceEntretienKm,
    this.frequenceEntretienHeures,
    this.derniereMaintenanceDate,
    this.derniereMaintenanceType,
    this.prochaineMaintenancePrevue,
    this.garagePrestataire,
    this.historiquePannes,
    this.piecesCritiques,
    this.kmParcourus,
    this.tonnageTransporte,
    this.nombreRotations,
    this.tempsImmobilisation,
    this.tauxDisponibilite,
    this.coutParKm,
    this.coutParTonne,
    this.rentabilite,
    this.identifiantGPS,
    this.fournisseurGPS,
    this.positionActuelle,
    this.alerteVitesse,
    this.alerteSortieZone,
    this.alerteArretNonAutorise,
    this.updatedAt,
    this.isActive = true,
    this.notes,
    this.radarNumber,
    this.horsServiceAt,
    this.horsServiceReason,
  });

  /// Conversion depuis Firestore
  factory TruckModel.fromMap(Map<String, dynamic> map, String id) {
    return TruckModel(
      id: id,
      proprietaire: map['proprietaire'] as String? ?? '',
      numeroInterneFlotte: map['numeroInterneFlotte'] as String? ?? '',
      immatriculation: map['immatriculation'] as String? ?? '',
      numeroChassis: map['numeroChassis'] as String? ?? '',
      marque: map['marque'] as String? ?? '',
      modele: map['modele'] as String? ?? '',
      anneeFabrication: map['anneeFabrication'] as int? ?? DateTime.now().year,
      numeroCarteGrise: map['numeroCarteGrise'] as String?,
      dateMiseEnCirculation: map['dateMiseEnCirculation'] != null
          ? (map['dateMiseEnCirculation'] as Timestamp).toDate()
          : null,
      dateEntreeFlotte: map['dateEntreeFlotte'] != null
          ? (map['dateEntreeFlotte'] as Timestamp).toDate()
          : DateTime.now(),
      assuranceCompagnie: map['assuranceCompagnie'] as String?,
      assuranceNumeroPolice: map['assuranceNumeroPolice'] as String?,
      assuranceDateDebut: map['assuranceDateDebut'] != null
          ? (map['assuranceDateDebut'] as Timestamp).toDate()
          : null,
      assuranceDateFin: map['assuranceDateFin'] != null
          ? (map['assuranceDateFin'] as Timestamp).toDate()
          : null,
      visiteTechniqueDerniere: map['visiteTechniqueDerniere'] != null
          ? (map['visiteTechniqueDerniere'] as Timestamp).toDate()
          : null,
      visiteTechniqueProchaine: map['visiteTechniqueProchaine'] != null
          ? (map['visiteTechniqueProchaine'] as Timestamp).toDate()
          : null,
      paysOrigine: map['paysOrigine'] as String?,
      type: TruckType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TruckType.porteur,
      ),
      configuration: TruckConfiguration.values.firstWhere(
        (e) => e.name == map['configuration'],
        orElse: () => TruckConfiguration.config4x2,
      ),
      couleur: map['couleur'] as String?,
      numeroMoteur: map['numeroMoteur'] as String?,
      normeMoteur: map['normeMoteur'] as String?,
      typeMoteur: map['typeMoteur'] as String?,
      puissanceCV: map['puissanceCV'] as int?,
      puissanceKW: map['puissanceKW'] as int?,
      cylindree: map['cylindree'] as int?,
      typeCarburant: map['typeCarburant'] != null
          ? FuelType.values.firstWhere(
              (e) => e.name == map['typeCarburant'],
              orElse: () => FuelType.diesel,
            )
          : null,
      capaciteReservoir: map['capaciteReservoir'] as int?,
      boiteVitesses: map['boiteVitesses'] != null
          ? GearboxType.values.firstWhere(
              (e) => e.name == map['boiteVitesses'],
              orElse: () => GearboxType.manuelle,
            )
          : null,
      nombreRapports: map['nombreRapports'] as int?,
      typeEmbrayage: map['typeEmbrayage'] as String?,
      poidsAVide: (map['poidsAVide'] as num?)?.toDouble(),
      ptac: (map['ptac'] as num?)?.toDouble(),
      ptra: (map['ptra'] as num?)?.toDouble(),
      chargeUtileMax: (map['chargeUtileMax'] as num?)?.toDouble(),
      volumeUtile: (map['volumeUtile'] as num?)?.toDouble(),
      longueur: (map['longueur'] as num?)?.toDouble(),
      largeur: (map['largeur'] as num?)?.toDouble(),
      hauteur: (map['hauteur'] as num?)?.toDouble(),
      statut: TruckStatus.values.firstWhere(
        (e) => e.name == map['statut'],
        orElse: () => TruckStatus.enService,
      ),
      siteAffectation: map['siteAffectation'] as String?,
      zoneExploitation: map['zoneExploitation'] as String?,
      typeActivite: map['typeActivite'] != null
          ? ActivityType.values.firstWhere(
              (e) => e.name == map['typeActivite'],
              orElse: () => ActivityType.chantier,
            )
          : null,
      chauffeurPrincipalId: map['chauffeurPrincipalId'] as String?,
      chauffeurSecondaireId: map['chauffeurSecondaireId'] as String?,
      responsableFlotteId: map['responsableFlotteId'] as String?,
      kilometrageInitial: map['kilometrageInitial'] as int? ?? 0,
      kilometrageActuel: map['kilometrageActuel'] as int? ?? 0,
      heuresMoteur: map['heuresMoteur'] as int?,
      planMaintenance: map['planMaintenance'] != null
          ? MaintenancePlan.values.firstWhere(
              (e) => e.name == map['planMaintenance'],
              orElse: () => MaintenancePlan.parKilometrage,
            )
          : null,
      frequenceEntretienKm: map['frequenceEntretienKm'] as int?,
      frequenceEntretienHeures: map['frequenceEntretienHeures'] as int?,
      derniereMaintenanceDate: map['derniereMaintenanceDate'] != null
          ? (map['derniereMaintenanceDate'] as Timestamp).toDate()
          : null,
      derniereMaintenanceType: map['derniereMaintenanceType'] as String?,
      prochaineMaintenancePrevue: map['prochaineMaintenancePrevue'] != null
          ? (map['prochaineMaintenancePrevue'] as Timestamp).toDate()
          : null,
      garagePrestataire: map['garagePrestataire'] as String?,
      historiquePannes: map['historiquePannes'] != null
          ? List<String>.from(map['historiquePannes'] as List)
          : null,
      piecesCritiques: map['piecesCritiques'] != null
          ? List<String>.from(map['piecesCritiques'] as List)
          : null,
      kmParcourus: map['kmParcourus'] as int?,
      tonnageTransporte: (map['tonnageTransporte'] as num?)?.toDouble(),
      nombreRotations: map['nombreRotations'] as int?,
      tempsImmobilisation: map['tempsImmobilisation'] as int?,
      tauxDisponibilite: (map['tauxDisponibilite'] as num?)?.toDouble(),
      coutParKm: (map['coutParKm'] as num?)?.toDouble(),
      coutParTonne: (map['coutParTonne'] as num?)?.toDouble(),
      rentabilite: (map['rentabilite'] as num?)?.toDouble(),
      identifiantGPS: map['identifiantGPS'] as String?,
      fournisseurGPS: map['fournisseurGPS'] as String?,
      positionActuelle: map['positionActuelle'] as Map<String, dynamic>?,
      alerteVitesse: map['alerteVitesse'] as bool?,
      alerteSortieZone: map['alerteSortieZone'] as bool?,
      alerteArretNonAutorise: map['alerteArretNonAutorise'] as bool?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isActive: map['isActive'] as bool? ?? true,
      notes: map['notes'] as String?,
      fleetId: map['fleetId'] as String?,
      radarNumber: map['radarNumber'] as String?,
      horsServiceAt: map['horsServiceAt'] != null
          ? (map['horsServiceAt'] as Timestamp).toDate()
          : null,
      horsServiceReason: map['horsServiceReason'] as String?,
    );
  }
  // ============ IDENTIFICATION GÉNÉRALE ============
  final String id;
  final String proprietaire;
  final String numeroInterneFlotte;
  final String immatriculation;
  final String numeroChassis; // VIN
  final String marque;
  final String modele;
  final int anneeFabrication;
  final String? numeroCarteGrise;
  final DateTime? dateMiseEnCirculation;
  final DateTime dateEntreeFlotte;

  // Assurance
  final String? assuranceCompagnie;
  final String? assuranceNumeroPolice;
  final DateTime? assuranceDateDebut;
  final DateTime? assuranceDateFin;

  // Visite technique
  final DateTime? visiteTechniqueDerniere;
  final DateTime? visiteTechniqueProchaine;

  final String? paysOrigine;
  final TruckType type;
  final TruckConfiguration configuration;
  final String? couleur;
  final String? numeroMoteur;
  final String? normeMoteur; // Euro 3, 4, 5, etc.

  // ============ CARACTÉRISTIQUES TECHNIQUES ============

  // Motorisation
  final String? typeMoteur;
  final int? puissanceCV;
  final int? puissanceKW;
  final int? cylindree;
  final FuelType? typeCarburant;
  final int? capaciteReservoir; // en litres

  // Transmission
  final GearboxType? boiteVitesses;
  final int? nombreRapports;
  final String? typeEmbrayage;

  // Capacités
  final double? poidsAVide; // en kg
  final double? ptac; // Poids Total Autorisé en Charge
  final double? ptra; // Poids Total Roulant Autorisé
  final double? chargeUtileMax; // en tonnes
  final double? volumeUtile; // en m³

  // Dimensions
  final double? longueur; // en mètres
  final double? largeur; // en mètres
  final double? hauteur; // en mètres

  // ============ DONNÉES D'EXPLOITATION ============
  final TruckStatus statut;
  final String? siteAffectation;
  final String? zoneExploitation;
  final ActivityType? typeActivite;

  // Chauffeurs assignés (IDs)
  final String? chauffeurPrincipalId;
  final String? chauffeurSecondaireId;

  final String? responsableFlotteId;
  final int kilometrageInitial;
  final int kilometrageActuel;
  final int? heuresMoteur;

  // ============ MAINTENANCE & ENTRETIEN ============
  final MaintenancePlan? planMaintenance;
  final int? frequenceEntretienKm; // tous les X km
  final int? frequenceEntretienHeures; // toutes les X heures
  final DateTime? derniereMaintenanceDate;
  final String? derniereMaintenanceType; // préventif/correctif
  final DateTime? prochaineMaintenancePrevue;
  final String? garagePrestataire;
  final List<String>? historiquePannes; // Liste d'IDs de pannes
  final List<String>? piecesCritiques; // Liste de pièces à surveiller

  // ============ PERFORMANCE & PRODUCTIVITÉ ============
  final int? kmParcourus; // période actuelle
  final double? tonnageTransporte; // période actuelle
  final int? nombreRotations; // période actuelle
  final int? tempsImmobilisation; // en heures
  final double? tauxDisponibilite; // en pourcentage
  final double? coutParKm;
  final double? coutParTonne;
  final double? rentabilite;

  // ============ SUIVI GPS & TÉLÉMATIQUE ============
  final String? identifiantGPS;
  final String? fournisseurGPS;
  final Map<String, dynamic>? positionActuelle; // {lat, lng, timestamp}
  final bool? alerteVitesse;
  final bool? alerteSortieZone;
  final bool? alerteArretNonAutorise;

  // ============ METADATA ============
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive; // Soft delete
  final String? notes;
  final String? fleetId;
  final String? radarNumber;
  final DateTime? horsServiceAt;
  final String? horsServiceReason;

  /// Getters utiles
  String get displayName => '$marque $modele ($immatriculation)';
  String get shortName => '$marque $modele';
  int get age => DateTime.now().year - anneeFabrication;
  int get kilometrageTotal => kilometrageActuel - kilometrageInitial;

  bool get hasAssurance => assuranceDateFin != null &&
      assuranceDateFin!.isAfter(DateTime.now());

  bool get visiteTechniqueValide => visiteTechniqueProchaine != null &&
      visiteTechniqueProchaine!.isAfter(DateTime.now());

  bool get maintenanceAVenir => prochaineMaintenancePrevue != null &&
      prochaineMaintenancePrevue!.isBefore(
        DateTime.now().add(const Duration(days: 30)),
      );

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'proprietaire': proprietaire,
      'numeroInterneFlotte': numeroInterneFlotte,
      'immatriculation': immatriculation,
      'numeroChassis': numeroChassis,
      'marque': marque,
      'modele': modele,
      'anneeFabrication': anneeFabrication,
      'numeroCarteGrise': numeroCarteGrise,
      'dateMiseEnCirculation': dateMiseEnCirculation != null
          ? Timestamp.fromDate(dateMiseEnCirculation!)
          : null,
      'dateEntreeFlotte': Timestamp.fromDate(dateEntreeFlotte),
      'assuranceCompagnie': assuranceCompagnie,
      'assuranceNumeroPolice': assuranceNumeroPolice,
      'assuranceDateDebut': assuranceDateDebut != null
          ? Timestamp.fromDate(assuranceDateDebut!)
          : null,
      'assuranceDateFin': assuranceDateFin != null
          ? Timestamp.fromDate(assuranceDateFin!)
          : null,
      'visiteTechniqueDerniere': visiteTechniqueDerniere != null
          ? Timestamp.fromDate(visiteTechniqueDerniere!)
          : null,
      'visiteTechniqueProchaine': visiteTechniqueProchaine != null
          ? Timestamp.fromDate(visiteTechniqueProchaine!)
          : null,
      'paysOrigine': paysOrigine,
      'type': type.name,
      'configuration': configuration.name,
      'couleur': couleur,
      'numeroMoteur': numeroMoteur,
      'normeMoteur': normeMoteur,
      'typeMoteur': typeMoteur,
      'puissanceCV': puissanceCV,
      'puissanceKW': puissanceKW,
      'cylindree': cylindree,
      'typeCarburant': typeCarburant?.name,
      'capaciteReservoir': capaciteReservoir,
      'boiteVitesses': boiteVitesses?.name,
      'nombreRapports': nombreRapports,
      'typeEmbrayage': typeEmbrayage,
      'poidsAVide': poidsAVide,
      'ptac': ptac,
      'ptra': ptra,
      'chargeUtileMax': chargeUtileMax,
      'volumeUtile': volumeUtile,
      'longueur': longueur,
      'largeur': largeur,
      'hauteur': hauteur,
      'statut': statut.name,
      'siteAffectation': siteAffectation,
      'zoneExploitation': zoneExploitation,
      'typeActivite': typeActivite?.name,
      'chauffeurPrincipalId': chauffeurPrincipalId,
      'chauffeurSecondaireId': chauffeurSecondaireId,
      'responsableFlotteId': responsableFlotteId,
      'kilometrageInitial': kilometrageInitial,
      'kilometrageActuel': kilometrageActuel,
      'heuresMoteur': heuresMoteur,
      'planMaintenance': planMaintenance?.name,
      'frequenceEntretienKm': frequenceEntretienKm,
      'frequenceEntretienHeures': frequenceEntretienHeures,
      'derniereMaintenanceDate': derniereMaintenanceDate != null
          ? Timestamp.fromDate(derniereMaintenanceDate!)
          : null,
      'derniereMaintenanceType': derniereMaintenanceType,
      'prochaineMaintenancePrevue': prochaineMaintenancePrevue != null
          ? Timestamp.fromDate(prochaineMaintenancePrevue!)
          : null,
      'garagePrestataire': garagePrestataire,
      'historiquePannes': historiquePannes,
      'piecesCritiques': piecesCritiques,
      'kmParcourus': kmParcourus,
      'tonnageTransporte': tonnageTransporte,
      'nombreRotations': nombreRotations,
      'tempsImmobilisation': tempsImmobilisation,
      'tauxDisponibilite': tauxDisponibilite,
      'coutParKm': coutParKm,
      'coutParTonne': coutParTonne,
      'rentabilite': rentabilite,
      'identifiantGPS': identifiantGPS,
      'fournisseurGPS': fournisseurGPS,
      'positionActuelle': positionActuelle,
      'alerteVitesse': alerteVitesse,
      'alerteSortieZone': alerteSortieZone,
      'alerteArretNonAutorise': alerteArretNonAutorise,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'notes': notes,
      'fleetId': fleetId,
      'radarNumber': radarNumber,
      'horsServiceAt': horsServiceAt != null
          ? Timestamp.fromDate(horsServiceAt!)
          : null,
      'horsServiceReason': horsServiceReason,
    };
  }

  /// CopyWith pour modification immutable
  TruckModel copyWith({
    String? id,
    String? proprietaire,
    String? numeroInterneFlotte,
    String? immatriculation,
    String? numeroChassis,
    String? marque,
    String? modele,
    int? anneeFabrication,
    String? numeroCarteGrise,
    DateTime? dateMiseEnCirculation,
    DateTime? dateEntreeFlotte,
    String? assuranceCompagnie,
    String? assuranceNumeroPolice,
    DateTime? assuranceDateDebut,
    DateTime? assuranceDateFin,
    DateTime? visiteTechniqueDerniere,
    DateTime? visiteTechniqueProchaine,
    String? paysOrigine,
    TruckType? type,
    TruckConfiguration? configuration,
    String? couleur,
    String? numeroMoteur,
    String? normeMoteur,
    String? typeMoteur,
    int? puissanceCV,
    int? puissanceKW,
    int? cylindree,
    FuelType? typeCarburant,
    int? capaciteReservoir,
    GearboxType? boiteVitesses,
    int? nombreRapports,
    String? typeEmbrayage,
    double? poidsAVide,
    double? ptac,
    double? ptra,
    double? chargeUtileMax,
    double? volumeUtile,
    double? longueur,
    double? largeur,
    double? hauteur,
    TruckStatus? statut,
    String? siteAffectation,
    String? zoneExploitation,
    ActivityType? typeActivite,
    String? chauffeurPrincipalId,
    String? chauffeurSecondaireId,
    String? responsableFlotteId,
    int? kilometrageInitial,
    int? kilometrageActuel,
    int? heuresMoteur,
    MaintenancePlan? planMaintenance,
    int? frequenceEntretienKm,
    int? frequenceEntretienHeures,
    DateTime? derniereMaintenanceDate,
    String? derniereMaintenanceType,
    DateTime? prochaineMaintenancePrevue,
    String? garagePrestataire,
    List<String>? historiquePannes,
    List<String>? piecesCritiques,
    int? kmParcourus,
    double? tonnageTransporte,
    int? nombreRotations,
    int? tempsImmobilisation,
    double? tauxDisponibilite,
    double? coutParKm,
    double? coutParTonne,
    double? rentabilite,
    String? identifiantGPS,
    String? fournisseurGPS,
    Map<String, dynamic>? positionActuelle,
    bool? alerteVitesse,
    bool? alerteSortieZone,
    bool? alerteArretNonAutorise,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? notes,
    String? fleetId,
    String? radarNumber,
    DateTime? horsServiceAt,
    String? horsServiceReason,
  }) {
    return TruckModel(
      id: id ?? this.id,
      proprietaire: proprietaire ?? this.proprietaire,
      numeroInterneFlotte: numeroInterneFlotte ?? this.numeroInterneFlotte,
      immatriculation: immatriculation ?? this.immatriculation,
      numeroChassis: numeroChassis ?? this.numeroChassis,
      marque: marque ?? this.marque,
      modele: modele ?? this.modele,
      anneeFabrication: anneeFabrication ?? this.anneeFabrication,
      numeroCarteGrise: numeroCarteGrise ?? this.numeroCarteGrise,
      dateMiseEnCirculation:
          dateMiseEnCirculation ?? this.dateMiseEnCirculation,
      dateEntreeFlotte: dateEntreeFlotte ?? this.dateEntreeFlotte,
      assuranceCompagnie: assuranceCompagnie ?? this.assuranceCompagnie,
      assuranceNumeroPolice:
          assuranceNumeroPolice ?? this.assuranceNumeroPolice,
      assuranceDateDebut: assuranceDateDebut ?? this.assuranceDateDebut,
      assuranceDateFin: assuranceDateFin ?? this.assuranceDateFin,
      visiteTechniqueDerniere:
          visiteTechniqueDerniere ?? this.visiteTechniqueDerniere,
      visiteTechniqueProchaine:
          visiteTechniqueProchaine ?? this.visiteTechniqueProchaine,
      paysOrigine: paysOrigine ?? this.paysOrigine,
      type: type ?? this.type,
      configuration: configuration ?? this.configuration,
      couleur: couleur ?? this.couleur,
      numeroMoteur: numeroMoteur ?? this.numeroMoteur,
      normeMoteur: normeMoteur ?? this.normeMoteur,
      typeMoteur: typeMoteur ?? this.typeMoteur,
      puissanceCV: puissanceCV ?? this.puissanceCV,
      puissanceKW: puissanceKW ?? this.puissanceKW,
      cylindree: cylindree ?? this.cylindree,
      typeCarburant: typeCarburant ?? this.typeCarburant,
      capaciteReservoir: capaciteReservoir ?? this.capaciteReservoir,
      boiteVitesses: boiteVitesses ?? this.boiteVitesses,
      nombreRapports: nombreRapports ?? this.nombreRapports,
      typeEmbrayage: typeEmbrayage ?? this.typeEmbrayage,
      poidsAVide: poidsAVide ?? this.poidsAVide,
      ptac: ptac ?? this.ptac,
      ptra: ptra ?? this.ptra,
      chargeUtileMax: chargeUtileMax ?? this.chargeUtileMax,
      volumeUtile: volumeUtile ?? this.volumeUtile,
      longueur: longueur ?? this.longueur,
      largeur: largeur ?? this.largeur,
      hauteur: hauteur ?? this.hauteur,
      statut: statut ?? this.statut,
      siteAffectation: siteAffectation ?? this.siteAffectation,
      zoneExploitation: zoneExploitation ?? this.zoneExploitation,
      typeActivite: typeActivite ?? this.typeActivite,
      chauffeurPrincipalId: chauffeurPrincipalId ?? this.chauffeurPrincipalId,
      chauffeurSecondaireId:
          chauffeurSecondaireId ?? this.chauffeurSecondaireId,
      responsableFlotteId: responsableFlotteId ?? this.responsableFlotteId,
      kilometrageInitial: kilometrageInitial ?? this.kilometrageInitial,
      kilometrageActuel: kilometrageActuel ?? this.kilometrageActuel,
      heuresMoteur: heuresMoteur ?? this.heuresMoteur,
      planMaintenance: planMaintenance ?? this.planMaintenance,
      frequenceEntretienKm: frequenceEntretienKm ?? this.frequenceEntretienKm,
      frequenceEntretienHeures:
          frequenceEntretienHeures ?? this.frequenceEntretienHeures,
      derniereMaintenanceDate:
          derniereMaintenanceDate ?? this.derniereMaintenanceDate,
      derniereMaintenanceType:
          derniereMaintenanceType ?? this.derniereMaintenanceType,
      prochaineMaintenancePrevue:
          prochaineMaintenancePrevue ?? this.prochaineMaintenancePrevue,
      garagePrestataire: garagePrestataire ?? this.garagePrestataire,
      historiquePannes: historiquePannes ?? this.historiquePannes,
      piecesCritiques: piecesCritiques ?? this.piecesCritiques,
      kmParcourus: kmParcourus ?? this.kmParcourus,
      tonnageTransporte: tonnageTransporte ?? this.tonnageTransporte,
      nombreRotations: nombreRotations ?? this.nombreRotations,
      tempsImmobilisation: tempsImmobilisation ?? this.tempsImmobilisation,
      tauxDisponibilite: tauxDisponibilite ?? this.tauxDisponibilite,
      coutParKm: coutParKm ?? this.coutParKm,
      coutParTonne: coutParTonne ?? this.coutParTonne,
      rentabilite: rentabilite ?? this.rentabilite,
      identifiantGPS: identifiantGPS ?? this.identifiantGPS,
      fournisseurGPS: fournisseurGPS ?? this.fournisseurGPS,
      positionActuelle: positionActuelle ?? this.positionActuelle,
      alerteVitesse: alerteVitesse ?? this.alerteVitesse,
      alerteSortieZone: alerteSortieZone ?? this.alerteSortieZone,
      alerteArretNonAutorise:
          alerteArretNonAutorise ?? this.alerteArretNonAutorise,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      fleetId: fleetId ?? this.fleetId,
      radarNumber: radarNumber ?? this.radarNumber,
      horsServiceAt: horsServiceAt ?? this.horsServiceAt,
      horsServiceReason: horsServiceReason ?? this.horsServiceReason,
    );
  }
}
