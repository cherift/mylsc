import 'package:cloud_firestore/cloud_firestore.dart';

/// Client concerné par une pesée (ex. CBG, TBA, GEMIC)
class ClientModel {
  const ClientModel({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.createdBy,
    this.code,
    this.description,
    this.isActive = true,
  });

  factory ClientModel.fromMap(Map<String, dynamic> map, String id) {
    return ClientModel(
      id: id,
      name: map['name'] as String? ?? '',
      code: map['code'] as String?,
      description: map['description'] as String?,
      createdAt:
          (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: map['createdBy'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String name;
  final String? code;
  final String? description;
  final DateTime createdAt;
  final String createdBy;
  final bool isActive;

  /// Libellé affiché dans les listes déroulantes et rapports
  String get displayName =>
      (code != null && code!.isNotEmpty && code != name) ? '$name ($code)' : name;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'isActive': isActive,
    };
  }

  ClientModel copyWith({
    String? id,
    String? name,
    String? code,
    String? description,
    DateTime? createdAt,
    String? createdBy,
    bool? isActive,
  }) {
    return ClientModel(
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      isActive: isActive ?? this.isActive,
    );
  }
}
