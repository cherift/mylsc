import 'package:cloud_firestore/cloud_firestore.dart';

/// Gravité de la panne
enum BreakdownSeverity {
  minor('Mineure'),
  moderate('Modérée'),
  major('Majeure'),
  critical('Critique');

  const BreakdownSeverity(this.label);
  final String label;

  static BreakdownSeverity fromString(String value) {
    switch (value) {
      case 'minor':
        return BreakdownSeverity.minor;
      case 'moderate':
        return BreakdownSeverity.moderate;
      case 'major':
        return BreakdownSeverity.major;
      case 'critical':
        return BreakdownSeverity.critical;
      default:
        return BreakdownSeverity.moderate;
    }
  }
}

/// Statut du signalement de panne
enum BreakdownStatus {
  pending('En attente'),
  diagnosed('Diagnostiqué'),
  underRepair('En réparation'),
  repaired('Réparée'),
  cancelled('Annulée');

  const BreakdownStatus(this.label);
  final String label;

  static BreakdownStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BreakdownStatus.pending;
      case 'diagnosed':
        return BreakdownStatus.diagnosed;
      case 'underRepair':
        return BreakdownStatus.underRepair;
      case 'repaired':
        return BreakdownStatus.repaired;
      case 'cancelled':
        return BreakdownStatus.cancelled;
      default:
        return BreakdownStatus.pending;
    }
  }
}

/// Modèle pour un signalement de panne
class BreakdownReportModel {
  const BreakdownReportModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.reportedBy,
    required this.reportedByName,
    required this.severity,
    required this.description,
    required this.status,
    required this.createdAt,
    this.truckFleetNumber,
    this.location,
    this.photoUrls,
    this.diagnosedBy,
    this.diagnosedByName,
    this.diagnosedAt,
    this.diagnosis,
    this.estimatedRepairDuration,
    this.repairedBy,
    this.repairedByName,
    this.repairedAt,
    this.repairNotes,
    this.repairCost,
    this.cancellationReason,
  });

  factory BreakdownReportModel.fromMap(Map<String, dynamic> map, String id) {
    return BreakdownReportModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      truckFleetNumber: map['truckFleetNumber'] as String?,
      reportedBy: map['reportedBy'] as String? ?? '',
      reportedByName: map['reportedByName'] as String? ?? '',
      severity: BreakdownSeverity.fromString(
          map['severity'] as String? ?? 'moderate'),
      description: map['description'] as String? ?? '',
      location: map['location'] as String?,
      photoUrls: (map['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      status: BreakdownStatus.fromString(
          map['status'] as String? ?? 'pending'),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      diagnosedBy: map['diagnosedBy'] as String?,
      diagnosedByName: map['diagnosedByName'] as String?,
      diagnosedAt: (map['diagnosedAt'] as Timestamp?)?.toDate(),
      diagnosis: map['diagnosis'] as String?,
      estimatedRepairDuration: map['estimatedRepairDuration'] as String?,
      repairedBy: map['repairedBy'] as String?,
      repairedByName: map['repairedByName'] as String?,
      repairedAt: (map['repairedAt'] as Timestamp?)?.toDate(),
      repairNotes: map['repairNotes'] as String?,
      repairCost: (map['repairCost'] as num?)?.toDouble(),
      cancellationReason: map['cancellationReason'] as String?,
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String? truckFleetNumber;

  // Signalement
  final String reportedBy;
  final String reportedByName;
  final BreakdownSeverity severity;
  final String description;
  final String? location;
  final List<String>? photoUrls;

  final BreakdownStatus status;
  final DateTime createdAt;

  // Diagnostic
  final String? diagnosedBy;
  final String? diagnosedByName;
  final DateTime? diagnosedAt;
  final String? diagnosis;
  final String? estimatedRepairDuration;

  // Réparation
  final String? repairedBy;
  final String? repairedByName;
  final DateTime? repairedAt;
  final String? repairNotes;
  final double? repairCost;

  // Annulation
  final String? cancellationReason;

  /// Date formatée pour affichage
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Heure formatée pour affichage
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Durée depuis le signalement
  Duration get timeSinceReport => DateTime.now().difference(createdAt);

  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'truckFleetNumber': truckFleetNumber,
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'severity': severity.name,
      'description': description,
      'location': location,
      'photoUrls': photoUrls,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'diagnosedBy': diagnosedBy,
      'diagnosedByName': diagnosedByName,
      'diagnosedAt':
          diagnosedAt != null ? Timestamp.fromDate(diagnosedAt!) : null,
      'diagnosis': diagnosis,
      'estimatedRepairDuration': estimatedRepairDuration,
      'repairedBy': repairedBy,
      'repairedByName': repairedByName,
      'repairedAt':
          repairedAt != null ? Timestamp.fromDate(repairedAt!) : null,
      'repairNotes': repairNotes,
      'repairCost': repairCost,
      'cancellationReason': cancellationReason,
    };
  }

  BreakdownReportModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    String? reportedBy,
    String? reportedByName,
    BreakdownSeverity? severity,
    String? description,
    String? location,
    List<String>? photoUrls,
    BreakdownStatus? status,
    DateTime? createdAt,
    String? diagnosedBy,
    String? diagnosedByName,
    DateTime? diagnosedAt,
    String? diagnosis,
    String? estimatedRepairDuration,
    String? repairedBy,
    String? repairedByName,
    DateTime? repairedAt,
    String? repairNotes,
    double? repairCost,
    String? cancellationReason,
  }) {
    return BreakdownReportModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation:
          truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      location: location ?? this.location,
      photoUrls: photoUrls ?? this.photoUrls,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      diagnosedBy: diagnosedBy ?? this.diagnosedBy,
      diagnosedByName: diagnosedByName ?? this.diagnosedByName,
      diagnosedAt: diagnosedAt ?? this.diagnosedAt,
      diagnosis: diagnosis ?? this.diagnosis,
      estimatedRepairDuration:
          estimatedRepairDuration ?? this.estimatedRepairDuration,
      repairedBy: repairedBy ?? this.repairedBy,
      repairedByName: repairedByName ?? this.repairedByName,
      repairedAt: repairedAt ?? this.repairedAt,
      repairNotes: repairNotes ?? this.repairNotes,
      repairCost: repairCost ?? this.repairCost,
      cancellationReason: cancellationReason ?? this.cancellationReason,
    );
  }
}
