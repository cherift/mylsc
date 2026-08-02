import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'une demande de carburant
enum FuelRequestStatus {
  pending('En attente'),
  fulfilled('Servie'),
  validated('Validée'),
  disputed('Contestée'),
  rejected('Rejetée'),
  cancelled('Annulée');

  const FuelRequestStatus(this.label);
  final String label;

  /// La demande peut être annulée seulement si elle n'a pas encore été servie
  bool get isCancellable =>
      this == FuelRequestStatus.pending;

  static FuelRequestStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return FuelRequestStatus.pending;
      case 'fulfilled':
        return FuelRequestStatus.fulfilled;
      case 'validated':
        return FuelRequestStatus.validated;
      case 'disputed':
        return FuelRequestStatus.disputed;
      case 'rejected':
        return FuelRequestStatus.rejected;
      case 'cancelled':
        return FuelRequestStatus.cancelled;
      default:
        return FuelRequestStatus.pending;
    }
  }
}

/// Modèle pour une demande de carburant
class FuelRequestModel {
  const FuelRequestModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.requestedBy,
    required this.requestedByName,
    required this.requestedLiters,
    required this.status,
    required this.createdAt,
    this.truckFleetNumber,
    this.driverId,
    this.driverName,
    this.reason,
    this.approvedBy,
    this.approvedByName,
    this.approvedAt,
    this.rejectionReason,
    this.fulfilledBy,
    this.fulfilledByName,
    this.fulfilledAt,
    this.fulfilledLiters,
    this.fuelEntryId,
    this.fleetId,
    this.shiftId,
    this.receiptPhotoUrl,
    this.receiptNumber,
    this.verificationCode,
    this.validatedBy,
    this.validatedByName,
    this.validatedAt,
    this.disputeReason,
    this.isAutoValidated = false,
    this.resolvedBy,
    this.resolvedByName,
    this.resolvedAt,
    this.resolutionNote,
    this.observation,
  });

  factory FuelRequestModel.fromMap(Map<String, dynamic> map, String id) {
    return FuelRequestModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      truckFleetNumber: map['truckFleetNumber'] as String?,
      driverId: map['driverId'] as String?,
      driverName: map['driverName'] as String?,
      requestedBy: map['requestedBy'] as String? ?? '',
      requestedByName: map['requestedByName'] as String? ?? '',
      requestedLiters: (map['requestedLiters'] as num?)?.toDouble() ?? 0,
      reason: map['reason'] as String?,
      status: FuelRequestStatus.fromString(
          map['status'] as String? ?? 'pending'),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      approvedBy: map['approvedBy'] as String?,
      approvedByName: map['approvedByName'] as String?,
      approvedAt: (map['approvedAt'] as Timestamp?)?.toDate(),
      rejectionReason: map['rejectionReason'] as String?,
      fulfilledBy: map['fulfilledBy'] as String?,
      fulfilledByName: map['fulfilledByName'] as String?,
      fulfilledAt: (map['fulfilledAt'] as Timestamp?)?.toDate(),
      fulfilledLiters: (map['fulfilledLiters'] as num?)?.toDouble(),
      fuelEntryId: map['fuelEntryId'] as String?,
      fleetId: map['fleetId'] as String?,
      shiftId: map['shiftId'] as String?,
      receiptPhotoUrl: map['receiptPhotoUrl'] as String?,
      receiptNumber: map['receiptNumber'] as String?,
      verificationCode: map['verificationCode'] as String?,
      validatedBy: map['validatedBy'] as String?,
      validatedByName: map['validatedByName'] as String?,
      validatedAt: (map['validatedAt'] as Timestamp?)?.toDate(),
      disputeReason: map['disputeReason'] as String?,
      isAutoValidated: map['isAutoValidated'] as bool? ?? false,
      resolvedBy: map['resolvedBy'] as String?,
      resolvedByName: map['resolvedByName'] as String?,
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolutionNote: map['resolutionNote'] as String?,
      observation: map['observation'] as String?,
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String? truckFleetNumber;
  final String? driverId;
  final String? driverName;
  final String requestedBy;
  final String requestedByName;
  final double requestedLiters;
  final String? reason;
  final FuelRequestStatus status;
  final DateTime createdAt;

  // Approbation
  final String? approvedBy;
  final String? approvedByName;
  final DateTime? approvedAt;
  final String? rejectionReason;

  // Exécution (pompiste)
  final String? fulfilledBy;
  final String? fulfilledByName;
  final DateTime? fulfilledAt;
  final double? fulfilledLiters;
  final String? fuelEntryId;
  final String? fleetId;
  final String? shiftId;
  final String? receiptPhotoUrl;
  final String? receiptNumber;
  final String? verificationCode;

  // Validation (superviseur)
  final String? validatedBy;
  final String? validatedByName;
  final DateTime? validatedAt;
  final String? disputeReason;
  final bool isAutoValidated;

  // Résolution (responsable opérations)
  final String? resolvedBy;
  final String? resolvedByName;
  final DateTime? resolvedAt;
  final String? resolutionNote;

  // Observation pompiste (écart quantité)
  final String? observation;

  /// Date formatée pour affichage
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Heure formatée pour affichage
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'truckFleetNumber': truckFleetNumber,
      'driverId': driverId,
      'driverName': driverName,
      'requestedBy': requestedBy,
      'requestedByName': requestedByName,
      'requestedLiters': requestedLiters,
      'reason': reason,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'approvedBy': approvedBy,
      'approvedByName': approvedByName,
      'approvedAt':
          approvedAt != null ? Timestamp.fromDate(approvedAt!) : null,
      'rejectionReason': rejectionReason,
      'fulfilledBy': fulfilledBy,
      'fulfilledByName': fulfilledByName,
      'fulfilledAt':
          fulfilledAt != null ? Timestamp.fromDate(fulfilledAt!) : null,
      'fulfilledLiters': fulfilledLiters,
      'fuelEntryId': fuelEntryId,
      'fleetId': fleetId,
      'shiftId': shiftId,
      'receiptPhotoUrl': receiptPhotoUrl,
      'receiptNumber': receiptNumber,
      'verificationCode': verificationCode,
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt':
          validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'disputeReason': disputeReason,
      'isAutoValidated': isAutoValidated,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolutionNote': resolutionNote,
      'observation': observation,
    };
  }

  FuelRequestModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    String? driverId,
    String? driverName,
    String? requestedBy,
    String? requestedByName,
    double? requestedLiters,
    String? reason,
    FuelRequestStatus? status,
    DateTime? createdAt,
    String? approvedBy,
    String? approvedByName,
    DateTime? approvedAt,
    String? rejectionReason,
    String? fulfilledBy,
    String? fulfilledByName,
    DateTime? fulfilledAt,
    double? fulfilledLiters,
    String? fuelEntryId,
    String? fleetId,
    String? shiftId,
    String? receiptPhotoUrl,
    String? receiptNumber,
    String? verificationCode,
    String? validatedBy,
    String? validatedByName,
    DateTime? validatedAt,
    String? disputeReason,
    bool? isAutoValidated,
    String? resolvedBy,
    String? resolvedByName,
    DateTime? resolvedAt,
    String? resolutionNote,
    String? observation,
  }) {
    return FuelRequestModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation:
          truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      requestedBy: requestedBy ?? this.requestedBy,
      requestedByName: requestedByName ?? this.requestedByName,
      requestedLiters: requestedLiters ?? this.requestedLiters,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedByName: approvedByName ?? this.approvedByName,
      approvedAt: approvedAt ?? this.approvedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      fulfilledBy: fulfilledBy ?? this.fulfilledBy,
      fulfilledByName: fulfilledByName ?? this.fulfilledByName,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
      fulfilledLiters: fulfilledLiters ?? this.fulfilledLiters,
      fuelEntryId: fuelEntryId ?? this.fuelEntryId,
      fleetId: fleetId ?? this.fleetId,
      shiftId: shiftId ?? this.shiftId,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      verificationCode: verificationCode ?? this.verificationCode,
      validatedBy: validatedBy ?? this.validatedBy,
      validatedByName: validatedByName ?? this.validatedByName,
      validatedAt: validatedAt ?? this.validatedAt,
      disputeReason: disputeReason ?? this.disputeReason,
      isAutoValidated: isAutoValidated ?? this.isAutoValidated,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolutionNote: resolutionNote ?? this.resolutionNote,
      observation: observation ?? this.observation,
    );
  }
}
