import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'une vacation
enum ShiftStatus {
  active('En cours'),
  ended('Terminée');

  const ShiftStatus(this.label);
  final String label;

  static ShiftStatus fromString(String value) {
    switch (value) {
      case 'active':
        return ShiftStatus.active;
      case 'ended':
        return ShiftStatus.ended;
      default:
        return ShiftStatus.active;
    }
  }
}

/// Modèle de vacation (prise de fonction / fin de vacation)
class ShiftModel {

  const ShiftModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.driverId,
    required this.driverName,
    required this.startTime, required this.createdAt, this.startedBy,
    this.startedByName,
    this.endTime,
    this.status = ShiftStatus.active,
    this.isActive = true,
  });

  factory ShiftModel.fromMap(Map<String, dynamic> map, String id) {
    return ShiftModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      startedBy: map['startedBy'] as String?,
      startedByName: map['startedByName'] as String?,
      startTime: (map['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (map['endTime'] as Timestamp?)?.toDate(),
      status: ShiftStatus.fromString(map['status'] as String? ?? 'active'),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }
  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String driverId;
  final String driverName;
  final String? startedBy;
  final String? startedByName;
  final DateTime startTime;
  final DateTime? endTime;
  final ShiftStatus status;
  final DateTime createdAt;
  final bool isActive;

  /// Durée de la vacation
  Duration? get duration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  /// Vacation en cours
  bool get isOngoing => status == ShiftStatus.active;

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'driverId': driverId,
      'driverName': driverName,
      'startedBy': startedBy,
      'startedByName': startedByName,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }

  ShiftModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? driverId,
    String? driverName,
    String? startedBy,
    String? startedByName,
    DateTime? startTime,
    DateTime? endTime,
    ShiftStatus? status,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ShiftModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation: truckImmatriculation ?? this.truckImmatriculation,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      startedBy: startedBy ?? this.startedBy,
      startedByName: startedByName ?? this.startedByName,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
