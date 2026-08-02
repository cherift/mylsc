import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'une rotation
enum TripStatus {
  inProgress('En cours'),
  pendingValidation('En attente de validation'),
  validated('Validée'),
  rejected('Rejetée');

  const TripStatus(this.label);
  final String label;

  static TripStatus fromString(String value) {
    switch (value) {
      case 'inProgress':
        return TripStatus.inProgress;
      case 'pendingValidation':
        return TripStatus.pendingValidation;
      case 'validated':
        return TripStatus.validated;
      case 'rejected':
        return TripStatus.rejected;
      default:
        return TripStatus.inProgress;
    }
  }
}

/// Modèle pour une rotation (aller-retour mine ↔ port)
class TripModel {
  const TripModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.driverId,
    required this.driverName,
    required this.status,
    required this.createdAt,
    this.truckFleetNumber,
    this.shiftId,
    this.mineWeighingId,
    this.portWeighingId,
    this.mineWeight,
    this.portWeight,
    this.departureTime,
    this.arrivalTime,
    this.returnTime,
    this.notes,
    this.validatedBy,
    this.validatedByName,
    this.validatedAt,
    this.rejectionReason,
  });

  factory TripModel.fromMap(Map<String, dynamic> map, String id) {
    return TripModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      truckFleetNumber: map['truckFleetNumber'] as String?,
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      shiftId: map['shiftId'] as String?,
      mineWeighingId: map['mineWeighingId'] as String?,
      portWeighingId: map['portWeighingId'] as String?,
      mineWeight: (map['mineWeight'] as num?)?.toDouble(),
      portWeight: (map['portWeight'] as num?)?.toDouble(),
      departureTime: (map['departureTime'] as Timestamp?)?.toDate(),
      arrivalTime: (map['arrivalTime'] as Timestamp?)?.toDate(),
      returnTime: (map['returnTime'] as Timestamp?)?.toDate(),
      status:
          TripStatus.fromString(map['status'] as String? ?? 'inProgress'),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      notes: map['notes'] as String?,
      validatedBy: map['validatedBy'] as String?,
      validatedByName: map['validatedByName'] as String?,
      validatedAt: (map['validatedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String? truckFleetNumber;
  final String driverId;
  final String driverName;
  final String? shiftId;

  // Pesées liées
  final String? mineWeighingId;
  final String? portWeighingId;
  final double? mineWeight;
  final double? portWeight;

  // Horaires
  final DateTime? departureTime;
  final DateTime? arrivalTime;
  final DateTime? returnTime;

  final TripStatus status;
  final DateTime createdAt;
  final String? notes;

  // Validation
  final String? validatedBy;
  final String? validatedByName;
  final DateTime? validatedAt;
  final String? rejectionReason;

  /// Tonnage net transporté (poids mine - poids port, ou null si incomplet)
  double? get netTonnage {
    if (mineWeight != null && portWeight != null) {
      return (mineWeight! - portWeight!).abs();
    }
    return null;
  }

  /// Durée du trajet aller (départ mine → arrivée port)
  Duration? get tripDuration {
    if (departureTime != null && arrivalTime != null) {
      return arrivalTime!.difference(departureTime!);
    }
    return null;
  }

  /// Date formatée pour affichage
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Heure formatée pour affichage
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Tonnage net formaté
  String get formattedNetTonnage {
    final t = netTonnage;
    if (t == null) return '--';
    return '${t.toStringAsFixed(2)} T';
  }

  /// La rotation a les deux pesées
  bool get isComplete =>
      mineWeighingId != null && portWeighingId != null;

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'truckFleetNumber': truckFleetNumber,
      'driverId': driverId,
      'driverName': driverName,
      'shiftId': shiftId,
      'mineWeighingId': mineWeighingId,
      'portWeighingId': portWeighingId,
      'mineWeight': mineWeight,
      'portWeight': portWeight,
      'departureTime': departureTime != null
          ? Timestamp.fromDate(departureTime!)
          : null,
      'arrivalTime':
          arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
      'returnTime':
          returnTime != null ? Timestamp.fromDate(returnTime!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'notes': notes,
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt':
          validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'rejectionReason': rejectionReason,
    };
  }

  TripModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    String? driverId,
    String? driverName,
    String? shiftId,
    String? mineWeighingId,
    String? portWeighingId,
    double? mineWeight,
    double? portWeight,
    DateTime? departureTime,
    DateTime? arrivalTime,
    DateTime? returnTime,
    TripStatus? status,
    DateTime? createdAt,
    String? notes,
    String? validatedBy,
    String? validatedByName,
    DateTime? validatedAt,
    String? rejectionReason,
  }) {
    return TripModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation:
          truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      shiftId: shiftId ?? this.shiftId,
      mineWeighingId: mineWeighingId ?? this.mineWeighingId,
      portWeighingId: portWeighingId ?? this.portWeighingId,
      mineWeight: mineWeight ?? this.mineWeight,
      portWeight: portWeight ?? this.portWeight,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      returnTime: returnTime ?? this.returnTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedByName: validatedByName ?? this.validatedByName,
      validatedAt: validatedAt ?? this.validatedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }
}
