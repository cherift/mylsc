import 'package:cloud_firestore/cloud_firestore.dart';

/// Statut d'un signalement de panne
enum BreakdownStatus {
  pending('En attente'),
  inDiagnostic('En diagnostic'),
  inRepair('En réparation'),
  resolved('Résolue'),
  closed('Fermée');

  const BreakdownStatus(this.label);
  final String label;

  static BreakdownStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BreakdownStatus.pending;
      case 'inDiagnostic':
        return BreakdownStatus.inDiagnostic;
      case 'inRepair':
        return BreakdownStatus.inRepair;
      case 'resolved':
        return BreakdownStatus.resolved;
      case 'closed':
        return BreakdownStatus.closed;
      default:
        return BreakdownStatus.pending;
    }
  }
}

/// Sévérité d'une panne
enum BreakdownSeverity {
  low('Faible'),
  medium('Moyenne'),
  high('Élevée'),
  critical('Critique');

  const BreakdownSeverity(this.label);
  final String label;

  static BreakdownSeverity fromString(String value) {
    switch (value) {
      case 'low':
        return BreakdownSeverity.low;
      case 'medium':
        return BreakdownSeverity.medium;
      case 'high':
        return BreakdownSeverity.high;
      case 'critical':
        return BreakdownSeverity.critical;
      default:
        return BreakdownSeverity.medium;
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
    required this.description,
    required this.createdAt,
    this.truckFleetNumber,
    this.severity = BreakdownSeverity.medium,
    this.location,
    this.status = BreakdownStatus.pending,
    this.assignedTo,
    this.assignedToName,
    this.assignedAt,
    this.diagnosticResults,
    this.partsNeeded,
    this.estimatedRepairTime,
    this.estimatedCost,
    this.resolvedAt,
    this.resolvedBy,
    this.resolvedByName,
    this.actualRepairTime,
    this.actualCost,
    this.updatedAt,
    this.isActive = true,
  });

  factory BreakdownReportModel.fromMap(Map<String, dynamic> map, String id) {
    return BreakdownReportModel(
      id: id,
      truckId: map['truckId'] as String? ?? '',
      truckImmatriculation: map['truckImmatriculation'] as String? ?? '',
      truckFleetNumber: map['truckFleetNumber'] as String?,
      reportedBy: map['reportedBy'] as String? ?? '',
      reportedByName: map['reportedByName'] as String? ?? '',
      description: map['description'] as String? ?? '',
      severity: BreakdownSeverity.fromString(
          map['severity'] as String? ?? 'medium'),
      location: map['location'] as String?,
      status:
          BreakdownStatus.fromString(map['status'] as String? ?? 'pending'),
      assignedTo: map['assignedTo'] as String?,
      assignedToName: map['assignedToName'] as String?,
      assignedAt: (map['assignedAt'] as Timestamp?)?.toDate(),
      diagnosticResults: map['diagnosticResults'] as String?,
      partsNeeded: (map['partsNeeded'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      estimatedRepairTime: (map['estimatedRepairTime'] as num?)?.toDouble(),
      estimatedCost: (map['estimatedCost'] as num?)?.toDouble(),
      resolvedAt: (map['resolvedAt'] as Timestamp?)?.toDate(),
      resolvedBy: map['resolvedBy'] as String?,
      resolvedByName: map['resolvedByName'] as String?,
      actualRepairTime: (map['actualRepairTime'] as num?)?.toDouble(),
      actualCost: (map['actualCost'] as num?)?.toDouble(),
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String? truckFleetNumber;
  final String reportedBy;
  final String reportedByName;
  final String description;
  final BreakdownSeverity severity;
  final String? location;
  final BreakdownStatus status;

  // Assignation technicien
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedAt;

  // Diagnostic
  final String? diagnosticResults;
  final List<String>? partsNeeded;
  final double? estimatedRepairTime;
  final double? estimatedCost;

  // Résolution
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolvedByName;
  final double? actualRepairTime;
  final double? actualCost;

  // Métadonnées
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isActive;

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
      'reportedBy': reportedBy,
      'reportedByName': reportedByName,
      'description': description,
      'severity': severity.name,
      'location': location,
      'status': status.name,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedAt':
          assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'diagnosticResults': diagnosticResults,
      'partsNeeded': partsNeeded,
      'estimatedRepairTime': estimatedRepairTime,
      'estimatedCost': estimatedCost,
      'resolvedAt':
          resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'actualRepairTime': actualRepairTime,
      'actualCost': actualCost,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt':
          updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
    };
  }

  BreakdownReportModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    String? reportedBy,
    String? reportedByName,
    String? description,
    BreakdownSeverity? severity,
    String? location,
    BreakdownStatus? status,
    String? assignedTo,
    String? assignedToName,
    DateTime? assignedAt,
    String? diagnosticResults,
    List<String>? partsNeeded,
    double? estimatedRepairTime,
    double? estimatedCost,
    DateTime? resolvedAt,
    String? resolvedBy,
    String? resolvedByName,
    double? actualRepairTime,
    double? actualCost,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return BreakdownReportModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation:
          truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      reportedBy: reportedBy ?? this.reportedBy,
      reportedByName: reportedByName ?? this.reportedByName,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      location: location ?? this.location,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedToName: assignedToName ?? this.assignedToName,
      assignedAt: assignedAt ?? this.assignedAt,
      diagnosticResults: diagnosticResults ?? this.diagnosticResults,
      partsNeeded: partsNeeded ?? this.partsNeeded,
      estimatedRepairTime: estimatedRepairTime ?? this.estimatedRepairTime,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      resolvedByName: resolvedByName ?? this.resolvedByName,
      actualRepairTime: actualRepairTime ?? this.actualRepairTime,
      actualCost: actualCost ?? this.actualCost,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
