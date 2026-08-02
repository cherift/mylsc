import 'package:cloud_firestore/cloud_firestore.dart';

/// Rang du chauffeur dans son affectation
enum DriverRank {
  principal,
  secondaire,
  remplacant,
}

extension DriverRankExtension on DriverRank {
  String get label {
    switch (this) {
      case DriverRank.principal:
        return 'Principal';
      case DriverRank.secondaire:
        return 'Secondaire';
      case DriverRank.remplacant:
        return 'Remplaçant';
    }
  }

  String get i18nKey {
    switch (this) {
      case DriverRank.principal:
        return 'assignment.rankPrincipal';
      case DriverRank.secondaire:
        return 'assignment.rankSecondaire';
      case DriverRank.remplacant:
        return 'assignment.rankRemplacant';
    }
  }
}

/// Modèle d'affectation chauffeur à un camion
class DriverAssignmentModel {

  const DriverAssignmentModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.driverId,
    required this.driverName,
    required this.assignedBy,
    required this.assignedByName,
    required this.assignedAt,
    this.isPrimary = true,
    this.driverRank = DriverRank.principal,
    this.unassignedAt,
    this.isActive = true,
  });

  factory DriverAssignmentModel.fromMap(Map<String, dynamic> map, String id) {
    var rank = DriverRank.principal;
    final rankStr = map['driverRank'] as String?;
    if (rankStr != null) {
      rank = DriverRank.values.firstWhere(
        (r) => r.name == rankStr,
        orElse: () => DriverRank.principal,
      );
    }

    return DriverAssignmentModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      driverId: map['driverId'] as String? ?? '',
      driverName: map['driverName'] as String? ?? '',
      assignedBy: map['assignedBy'] as String? ?? '',
      assignedByName: map['assignedByName'] as String? ?? '',
      isPrimary: map['isPrimary'] as bool? ?? true,
      driverRank: rank,
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unassignedAt: (map['unassignedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String driverId;
  final String driverName;
  final String assignedBy;
  final String assignedByName;
  final bool isPrimary;
  final DriverRank driverRank;
  final DateTime assignedAt;
  final DateTime? unassignedAt;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'driverId': driverId,
      'driverName': driverName,
      'assignedBy': assignedBy,
      'assignedByName': assignedByName,
      'isPrimary': isPrimary,
      'driverRank': driverRank.name,
      'assignedAt': Timestamp.fromDate(assignedAt),
      'unassignedAt': unassignedAt != null ? Timestamp.fromDate(unassignedAt!) : null,
      'isActive': isActive,
    };
  }

  DriverAssignmentModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? driverId,
    String? driverName,
    String? assignedBy,
    String? assignedByName,
    bool? isPrimary,
    DriverRank? driverRank,
    DateTime? assignedAt,
    DateTime? unassignedAt,
    bool? isActive,
  }) {
    return DriverAssignmentModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation: truckImmatriculation ?? this.truckImmatriculation,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      assignedBy: assignedBy ?? this.assignedBy,
      assignedByName: assignedByName ?? this.assignedByName,
      isPrimary: isPrimary ?? this.isPrimary,
      driverRank: driverRank ?? this.driverRank,
      assignedAt: assignedAt ?? this.assignedAt,
      unassignedAt: unassignedAt ?? this.unassignedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
