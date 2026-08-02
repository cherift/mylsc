import 'package:cloud_firestore/cloud_firestore.dart';

/// Lieu de pesée
enum WeighingLocation {
  mine('Mine'),
  port('Port'),
  storage('Stockage');

  const WeighingLocation(this.label);
  final String label;

  static WeighingLocation fromString(String value) {
    switch (value) {
      case 'mine':
        return WeighingLocation.mine;
      case 'port':
        return WeighingLocation.port;
      case 'storage':
        return WeighingLocation.storage;
      default:
        return WeighingLocation.mine;
    }
  }
}

/// Statut d'un enregistrement de pesée
enum WeighingStatus {
  pending('En attente'),
  recorded('Enregistrée'),
  validated('Validée'),
  rejected('Rejetée'),
  loaded('Chargé'),
  unloaded('Déchargé');

  const WeighingStatus(this.label);
  final String label;

  static WeighingStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return WeighingStatus.pending;
      case 'recorded':
        return WeighingStatus.recorded;
      case 'validated':
        return WeighingStatus.validated;
      case 'rejected':
        return WeighingStatus.rejected;
      case 'loaded':
        return WeighingStatus.loaded;
      case 'unloaded':
        return WeighingStatus.unloaded;
      default:
        return WeighingStatus.pending;
    }
  }
}

/// Modèle pour un enregistrement de pesée (mine ou port)
class WeighingRecordModel {
  const WeighingRecordModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.location,
    required this.weight,
    required this.weighedBy,
    required this.weighedByName,
    required this.status,
    required this.createdAt,
    this.emptyWeight,
    this.loadedWeight,
    this.truckFleetNumber,
    this.driverId,
    this.driverName,
    this.shiftId,
    this.ticketNumber,
    this.notes,
    this.validatedBy,
    this.validatedByName,
    this.validatedAt,
    this.rejectionReason,
    this.photoUrls,
    this.weighedByMatricule,
    this.driverMatricule,
    this.chargedBy,
    this.chargedByName,
    this.chargedAt,
    this.dischargedBy,
    this.dischargedByName,
    this.dischargedAt,
  });

  factory WeighingRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return WeighingRecordModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      truckFleetNumber: map['truckFleetNumber'] as String?,
      location: WeighingLocation.fromString(
          map['location'] as String? ?? 'mine'),
      weight: (map['weight'] as num?)?.toDouble() ?? 0,
      emptyWeight: (map['emptyWeight'] as num?)?.toDouble(),
      loadedWeight: (map['loadedWeight'] as num?)?.toDouble(),
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      shiftId: map['shiftId'] as String?,
      ticketNumber: map['ticketNumber'] as String?,
      weighedBy: map['weighedBy'] as String? ?? '',
      weighedByName: map['weighedByName'] as String? ?? '',
      status: WeighingStatus.fromString(
          map['status'] as String? ?? 'pending'),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      validatedBy: map['validatedBy'] as String?,
      validatedByName: map['validatedByName'] as String?,
      validatedAt: (map['validatedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
      photoUrls: (map['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      weighedByMatricule: map['weighedByMatricule'] as String?,
      driverMatricule: map['driverMatricule'] as String?,
      chargedBy: map['chargedBy'] as String?,
      chargedByName: map['chargedByName'] as String?,
      chargedAt: (map['chargedAt'] as Timestamp?)?.toDate(),
      dischargedBy: map['dischargedBy'] as String?,
      dischargedByName: map['dischargedByName'] as String?,
      dischargedAt: (map['dischargedAt'] as Timestamp?)?.toDate(),
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String? truckFleetNumber;
  final WeighingLocation location;
  final double weight;
  final double? emptyWeight;
  final double? loadedWeight;
  final String? driverId;
  final String? driverName;
  final String? shiftId;
  final String? ticketNumber;
  final String weighedBy;
  final String weighedByName;
  final WeighingStatus status;
  final DateTime createdAt;
  final String? notes;

  // Validation
  final String? validatedBy;
  final String? validatedByName;
  final DateTime? validatedAt;
  final String? rejectionReason;
  final List<String>? photoUrls;
  final String? weighedByMatricule;
  final String? driverMatricule;

  // Charge / Décharge (Stockage)
  final String? chargedBy;
  final String? chargedByName;
  final DateTime? chargedAt;
  final String? dischargedBy;
  final String? dischargedByName;
  final DateTime? dischargedAt;

  /// Date formatée pour affichage
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Heure formatée pour affichage
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Poids formaté avec unité
  String get formattedWeight {
    return '${weight.toStringAsFixed(2)} T';
  }

  /// Poids à vide formaté
  String get formattedEmptyWeight {
    return emptyWeight != null ? '${emptyWeight!.toStringAsFixed(2)} T' : '-';
  }

  /// Poids chargé formaté
  String get formattedLoadedWeight {
    return loadedWeight != null ? '${loadedWeight!.toStringAsFixed(2)} T' : '-';
  }

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'truckFleetNumber': truckFleetNumber,
      'location': location.name,
      'weight': weight,
      'emptyWeight': emptyWeight,
      'loadedWeight': loadedWeight,
      'driverId': driverId,
      'driverName': driverName,
      'shiftId': shiftId,
      'ticketNumber': ticketNumber,
      'weighedBy': weighedBy,
      'weighedByName': weighedByName,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt':
          validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'rejectionReason': rejectionReason,
      'photoUrls': photoUrls,
      'weighedByMatricule': weighedByMatricule,
      'driverMatricule': driverMatricule,
      'chargedBy': chargedBy,
      'chargedByName': chargedByName,
      'chargedAt': chargedAt != null ? Timestamp.fromDate(chargedAt!) : null,
      'dischargedBy': dischargedBy,
      'dischargedByName': dischargedByName,
      'dischargedAt':
          dischargedAt != null ? Timestamp.fromDate(dischargedAt!) : null,
    };
  }

  WeighingRecordModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    WeighingLocation? location,
    double? weight,
    double? emptyWeight,
    double? loadedWeight,
    String? driverId,
    String? driverName,
    String? shiftId,
    String? ticketNumber,
    String? weighedBy,
    String? weighedByName,
    WeighingStatus? status,
    DateTime? createdAt,
    String? notes,
    String? validatedBy,
    String? validatedByName,
    DateTime? validatedAt,
    String? rejectionReason,
    List<String>? photoUrls,
    String? weighedByMatricule,
    String? driverMatricule,
    String? chargedBy,
    String? chargedByName,
    DateTime? chargedAt,
    String? dischargedBy,
    String? dischargedByName,
    DateTime? dischargedAt,
  }) {
    return WeighingRecordModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation:
          truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      location: location ?? this.location,
      weight: weight ?? this.weight,
      emptyWeight: emptyWeight ?? this.emptyWeight,
      loadedWeight: loadedWeight ?? this.loadedWeight,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      shiftId: shiftId ?? this.shiftId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      weighedBy: weighedBy ?? this.weighedBy,
      weighedByName: weighedByName ?? this.weighedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedByName: validatedByName ?? this.validatedByName,
      validatedAt: validatedAt ?? this.validatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      photoUrls: photoUrls ?? this.photoUrls,
      weighedByMatricule: weighedByMatricule ?? this.weighedByMatricule,
      driverMatricule: driverMatricule ?? this.driverMatricule,
      chargedBy: chargedBy ?? this.chargedBy,
      chargedByName: chargedByName ?? this.chargedByName,
      chargedAt: chargedAt ?? this.chargedAt,
      dischargedBy: dischargedBy ?? this.dischargedBy,
      dischargedByName: dischargedByName ?? this.dischargedByName,
      dischargedAt: dischargedAt ?? this.dischargedAt,
    );
  }
}
