enum VehicleState {
  bonEtat,
  bonEtatAvecObservation,
  nonFonctionnel,
  accidente,
  autres,
}

extension VehicleStateExtension on VehicleState {
  String get displayName {
    switch (this) {
      case VehicleState.bonEtat:
        return 'Bon état';
      case VehicleState.bonEtatAvecObservation:
        return 'Bon état avec observation';
      case VehicleState.nonFonctionnel:
        return 'Non fonctionnel';
      case VehicleState.accidente:
        return 'Accidenté';
      case VehicleState.autres:
        return 'Autres';
    }
  }

  /// Clé de traduction i18n pour ce statut
  String get i18nKey {
    switch (this) {
      case VehicleState.bonEtat:
        return 'inspection.bonEtat';
      case VehicleState.bonEtatAvecObservation:
        return 'inspection.bonEtatAvecObservation';
      case VehicleState.nonFonctionnel:
        return 'inspection.nonFonctionnel';
      case VehicleState.accidente:
        return 'inspection.accidente';
      case VehicleState.autres:
        return 'inspection.autres';
    }
  }
}

class VehicleInspectionModel {

  const VehicleInspectionModel({
    required this.id,
    required this.truckId,
    required this.inspectedBy,
    required this.inspectionDate,
    required this.state,
    required this.createdAt,
    this.truckImmatriculation,
    this.inspectedByName,
    this.observation,
    this.photoUrls,
    this.isActive = true,
  });

  factory VehicleInspectionModel.fromJson(Map<String, dynamic> json) {
    return VehicleInspectionModel(
      id: json['id'] as String,
      truckId: json['truckId'] as String,
      truckImmatriculation: json['truckImmatriculation'] as String?,
      inspectedBy: json['inspectedBy'] as String,
      inspectedByName: json['inspectedByName'] as String?,
      inspectionDate: DateTime.parse(json['inspectionDate'] as String),
      state: VehicleState.values.byName(json['state'] as String),
      observation: json['observation'] as String?,
      photoUrls: (json['photoUrls'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  final String id;
  final String truckId;
  final String? truckImmatriculation;
  final String inspectedBy;
  final String? inspectedByName;
  final DateTime inspectionDate;
  final VehicleState state;
  final String? observation;
  final List<String>? photoUrls;
  final DateTime createdAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'inspectedBy': inspectedBy,
      'inspectedByName': inspectedByName,
      'inspectionDate': inspectionDate.toIso8601String(),
      'state': state.name,
      'observation': observation,
      'photoUrls': photoUrls,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  VehicleInspectionModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? inspectedBy,
    String? inspectedByName,
    DateTime? inspectionDate,
    VehicleState? state,
    String? observation,
    List<String>? photoUrls,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return VehicleInspectionModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation: truckImmatriculation ?? this.truckImmatriculation,
      inspectedBy: inspectedBy ?? this.inspectedBy,
      inspectedByName: inspectedByName ?? this.inspectedByName,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      state: state ?? this.state,
      observation: observation ?? this.observation,
      photoUrls: photoUrls ?? this.photoUrls,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}
