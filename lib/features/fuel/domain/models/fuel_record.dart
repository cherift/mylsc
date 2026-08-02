import 'package:cloud_firestore/cloud_firestore.dart';

/// Type de ravitaillement
enum FuelTransactionType {
  ravitaillement('Ravitaillement'),
  correction('Correction'),
  siphonage('Siphonage');

  const FuelTransactionType(this.label);
  final String label;
}

/// Source du ravitaillement
enum FuelSource {
  stationService('Station-service'),
  cuveInterne('Cuve interne'),
  camionCiterne('Camion-citerne'),
  autre('Autre');

  const FuelSource(this.label);
  final String label;
}

/// Modèle d'un enregistrement de carburant
class FuelRecord {

  FuelRecord({
    required this.id,
    required this.truckId,
    required this.type,
    required this.date,
    required this.quantiteLitres,
    required this.niveauAvant,
    required this.niveauApres,
    required this.createdAt, this.pourcentageAvant,
    this.pourcentageApres,
    this.prixUnitaire,
    this.coutTotal,
    this.devise,
    this.kilometrage,
    this.heuresMoteur,
    this.pleinComplet = false,
    this.source,
    this.lieuRavitaillement,
    this.positionGPS,
    this.numeroTicket,
    this.numeroBonCommande,
    this.urlJustificatif,
    this.chauffeurId,
    this.chauffeurNom,
    this.fournisseur,
    this.numeroCartePetroliere,
    this.notes,
    this.createdBy,
    this.updatedAt,
    this.isDeleted = false,
  });

  /// Conversion depuis Firestore
  factory FuelRecord.fromMap(Map<String, dynamic> map, String id) {
    return FuelRecord(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      type: FuelTransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FuelTransactionType.ravitaillement,
      ),
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      quantiteLitres: (map['quantiteLitres'] as num?)?.toDouble() ?? 0,
      niveauAvant: (map['niveauAvant'] as num?)?.toDouble() ?? 0,
      niveauApres: (map['niveauApres'] as num?)?.toDouble() ?? 0,
      pourcentageAvant: (map['pourcentageAvant'] as num?)?.toDouble(),
      pourcentageApres: (map['pourcentageApres'] as num?)?.toDouble(),
      prixUnitaire: (map['prixUnitaire'] as num?)?.toDouble(),
      coutTotal: (map['coutTotal'] as num?)?.toDouble(),
      devise: map['devise'] as String?,
      kilometrage: map['kilometrage'] as int?,
      heuresMoteur: map['heuresMoteur'] as int?,
      pleinComplet: map['pleinComplet'] as bool? ?? false,
      source: map['source'] != null
          ? FuelSource.values.firstWhere(
              (e) => e.name == map['source'],
              orElse: () => FuelSource.stationService,
            )
          : null,
      lieuRavitaillement: map['lieuRavitaillement'] as String?,
      positionGPS: map['positionGPS'] as GeoPoint?,
      numeroTicket: map['numeroTicket'] as String?,
      numeroBonCommande: map['numeroBonCommande'] as String?,
      urlJustificatif: map['urlJustificatif'] as String?,
      chauffeurId: map['chauffeurId'] as String?,
      chauffeurNom: map['chauffeurNom'] as String?,
      fournisseur: map['fournisseur'] as String?,
      numeroCartePetroliere: map['numeroCartePetroliere'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      createdBy: map['createdBy'] as String?,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
      isDeleted: map['isDeleted'] as bool? ?? false,
    );
  }
  final String id;
  final String truckId;
  final FuelTransactionType type;
  final DateTime date;

  // Quantité et niveau
  final double quantiteLitres; // Litres ajoutés/retirés
  final double niveauAvant; // Niveau avant en litres
  final double niveauApres; // Niveau après en litres
  final double? pourcentageAvant; // Pourcentage avant (0-100)
  final double? pourcentageApres; // Pourcentage après (0-100)

  // Coût
  final double? prixUnitaire; // Prix par litre
  final double? coutTotal; // Coût total
  final String? devise; // EUR, XOF, USD, etc.

  // Kilométrage
  final int? kilometrage; // Kilométrage au moment du plein
  final int? heuresMoteur; // Heures moteur au moment du plein

  // Plein complet ?
  final bool pleinComplet; // Si true, permet calcul consommation

  // Source et lieu
  final FuelSource? source;
  final String? lieuRavitaillement;
  final GeoPoint? positionGPS;

  // Référence et justificatif
  final String? numeroTicket; // Numéro ticket/facture
  final String? numeroBonCommande;
  final String? urlJustificatif; // URL de la photo/scan du reçu

  // Chauffeur
  final String? chauffeurId;
  final String? chauffeurNom;

  // Fournisseur
  final String? fournisseur;
  final String? numeroCartePetroliere;

  // Notes
  final String? notes;

  // Metadata
  final DateTime createdAt;
  final String? createdBy;
  final DateTime? updatedAt;
  final bool isDeleted;

  /// Getters utiles
  String get displayDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get displayTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String get displayCost {
    if (coutTotal == null) return '-';
    final currency = devise ?? 'XOF';
    return '${coutTotal!.toStringAsFixed(0)} $currency';
  }

  String get displayPricePerLiter {
    if (prixUnitaire == null) return '-';
    final currency = devise ?? 'XOF';
    return '${prixUnitaire!.toStringAsFixed(0)} $currency/L';
  }

  /// Conversion vers Firestore
  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'quantiteLitres': quantiteLitres,
      'niveauAvant': niveauAvant,
      'niveauApres': niveauApres,
      'pourcentageAvant': pourcentageAvant,
      'pourcentageApres': pourcentageApres,
      'prixUnitaire': prixUnitaire,
      'coutTotal': coutTotal,
      'devise': devise,
      'kilometrage': kilometrage,
      'heuresMoteur': heuresMoteur,
      'pleinComplet': pleinComplet,
      'source': source?.name,
      'lieuRavitaillement': lieuRavitaillement,
      'positionGPS': positionGPS,
      'numeroTicket': numeroTicket,
      'numeroBonCommande': numeroBonCommande,
      'urlJustificatif': urlJustificatif,
      'chauffeurId': chauffeurId,
      'chauffeurNom': chauffeurNom,
      'fournisseur': fournisseur,
      'numeroCartePetroliere': numeroCartePetroliere,
      'notes': notes,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isDeleted': isDeleted,
    };
  }

  /// CopyWith
  FuelRecord copyWith({
    String? id,
    String? truckId,
    FuelTransactionType? type,
    DateTime? date,
    double? quantiteLitres,
    double? niveauAvant,
    double? niveauApres,
    double? pourcentageAvant,
    double? pourcentageApres,
    double? prixUnitaire,
    double? coutTotal,
    String? devise,
    int? kilometrage,
    int? heuresMoteur,
    bool? pleinComplet,
    FuelSource? source,
    String? lieuRavitaillement,
    GeoPoint? positionGPS,
    String? numeroTicket,
    String? numeroBonCommande,
    String? urlJustificatif,
    String? chauffeurId,
    String? chauffeurNom,
    String? fournisseur,
    String? numeroCartePetroliere,
    String? notes,
    DateTime? createdAt,
    String? createdBy,
    DateTime? updatedAt,
    bool? isDeleted,
  }) {
    return FuelRecord(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      type: type ?? this.type,
      date: date ?? this.date,
      quantiteLitres: quantiteLitres ?? this.quantiteLitres,
      niveauAvant: niveauAvant ?? this.niveauAvant,
      niveauApres: niveauApres ?? this.niveauApres,
      pourcentageAvant: pourcentageAvant ?? this.pourcentageAvant,
      pourcentageApres: pourcentageApres ?? this.pourcentageApres,
      prixUnitaire: prixUnitaire ?? this.prixUnitaire,
      coutTotal: coutTotal ?? this.coutTotal,
      devise: devise ?? this.devise,
      kilometrage: kilometrage ?? this.kilometrage,
      heuresMoteur: heuresMoteur ?? this.heuresMoteur,
      pleinComplet: pleinComplet ?? this.pleinComplet,
      source: source ?? this.source,
      lieuRavitaillement: lieuRavitaillement ?? this.lieuRavitaillement,
      positionGPS: positionGPS ?? this.positionGPS,
      numeroTicket: numeroTicket ?? this.numeroTicket,
      numeroBonCommande: numeroBonCommande ?? this.numeroBonCommande,
      urlJustificatif: urlJustificatif ?? this.urlJustificatif,
      chauffeurId: chauffeurId ?? this.chauffeurId,
      chauffeurNom: chauffeurNom ?? this.chauffeurNom,
      fournisseur: fournisseur ?? this.fournisseur,
      numeroCartePetroliere: numeroCartePetroliere ?? this.numeroCartePetroliere,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}

/// Statistiques de consommation de carburant
class FuelStatistics { // en %

  FuelStatistics({
    required this.truckId,
    required this.periodStart,
    required this.periodEnd,
    required this.totalLitres,
    required this.totalCout,
    required this.nombreRavitaillements,
    required this.moyennePrixLitre,
    this.consommationMoyenne,
    this.distanceParcourue,
    this.variationVsPeriodePrecedente,
  });
  final String truckId;
  final DateTime periodStart;
  final DateTime periodEnd;

  final double totalLitres;
  final double totalCout;
  final int nombreRavitaillements;
  final double moyennePrixLitre;

  // Consommation
  final double? consommationMoyenne; // L/100km
  final int? distanceParcourue; // km

  // Comparaison
  final double? variationVsPeriodePrecedente;

  String get displayConsommation {
    if (consommationMoyenne == null) return '-';
    return '${consommationMoyenne!.toStringAsFixed(1)} L/100km';
  }
}
