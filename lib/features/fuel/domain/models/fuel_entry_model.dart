import 'package:cloud_firestore/cloud_firestore.dart';

/// Modèle pour une entrée de carburant
class FuelEntryModel {
  const FuelEntryModel({
    required this.id,
    required this.truckId,
    required this.truckImmatriculation,
    required this.truckFleetNumber,
    required this.liters,
    required this.addedBy,
    required this.addedByName,
    required this.createdAt,
    this.receiptPhotoUrl,
    this.notes,
    this.truckBrand,
    this.truckModel,
  });

  /// Créer un FuelEntryModel depuis une Map (Firestore)
  factory FuelEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return FuelEntryModel(
      id: id,
      truckId: map['truckId'] as String,
      truckImmatriculation: map['truckImmatriculation'] as String,
      truckFleetNumber: map['truckFleetNumber'] as String,
      liters: (map['liters'] as num).toDouble(),
      addedBy: map['addedBy'] as String,
      addedByName: map['addedByName'] as String,
      receiptPhotoUrl: map['receiptPhotoUrl'] as String?,
      notes: map['notes'] as String?,
      truckBrand: map['truckBrand'] as String?,
      truckModel: map['truckModel'] as String?,
      createdAt: _parseDateTime(map['createdAt']) ?? DateTime.now(),
    );
  }

  /// Helper pour parser les DateTime depuis Firestore
  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  final String id;
  final String truckId;
  final String truckImmatriculation;
  final String truckFleetNumber;
  final double liters;
  final String? receiptPhotoUrl;
  final String addedBy;
  final String addedByName;
  final DateTime createdAt;
  final String? notes;
  final String? truckBrand;
  final String? truckModel;

  /// Nom complet du véhicule pour affichage
  String get truckDisplayName {
    if (truckBrand != null && truckModel != null) {
      return '$truckBrand $truckModel';
    }
    return truckImmatriculation;
  }

  /// Date formatée pour affichage
  String get formattedDate {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  /// Heure formatée pour affichage
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'truckFleetNumber': truckFleetNumber,
      'liters': liters,
      'receiptPhotoUrl': receiptPhotoUrl,
      'addedBy': addedBy,
      'addedByName': addedByName,
      'createdAt': createdAt.toIso8601String(),
      'notes': notes,
      'truckBrand': truckBrand,
      'truckModel': truckModel,
    };
  }

  FuelEntryModel copyWith({
    String? id,
    String? truckId,
    String? truckImmatriculation,
    String? truckFleetNumber,
    double? liters,
    String? receiptPhotoUrl,
    String? addedBy,
    String? addedByName,
    DateTime? createdAt,
    String? notes,
    String? truckBrand,
    String? truckModel,
  }) {
    return FuelEntryModel(
      id: id ?? this.id,
      truckId: truckId ?? this.truckId,
      truckImmatriculation: truckImmatriculation ?? this.truckImmatriculation,
      truckFleetNumber: truckFleetNumber ?? this.truckFleetNumber,
      liters: liters ?? this.liters,
      receiptPhotoUrl: receiptPhotoUrl ?? this.receiptPhotoUrl,
      addedBy: addedBy ?? this.addedBy,
      addedByName: addedByName ?? this.addedByName,
      createdAt: createdAt ?? this.createdAt,
      notes: notes ?? this.notes,
      truckBrand: truckBrand ?? this.truckBrand,
      truckModel: truckModel ?? this.truckModel,
    );
  }
}
