import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une flotte de camions
class FleetModel {
  const FleetModel({
    required this.id,
    required this.name,
    required this.supervisorId,
    required this.createdAt,
    required this.createdBy,
    this.description,
    this.isActive = true,
  });

  factory FleetModel.fromMap(Map<String, dynamic> map, String id) {
    return FleetModel(
      id: id,
      name: map['name'] as String? ?? '',
      description: map['description'] as String?,
      supervisorId: map['supervisorId'] as String? ?? '',
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String? description;
  final String supervisorId;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'supervisorId': supervisorId,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  FleetModel copyWith({
    String? id,
    String? name,
    String? description,
    String? supervisorId,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return FleetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      supervisorId: supervisorId ?? this.supervisorId,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
