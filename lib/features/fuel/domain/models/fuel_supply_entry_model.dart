import 'package:cloud_firestore/cloud_firestore.dart';

/// Entrée de ravitaillement du stock de carburant global.
/// Représente une livraison de carburant au dépôt (indépendant des camions).
class FuelSupplyEntryModel {
  const FuelSupplyEntryModel({
    required this.id,
    required this.date,
    required this.litersDelivered,
    required this.createdById,
    required this.createdByName,
    required this.createdAt,
    this.supplierName,
    this.invoiceNumber,
    this.pricePerLiter,
    this.notes,
    this.isValidated = false,
    this.validatedAt,
    this.validatedById,
    this.validatedByName,
  });

  factory FuelSupplyEntryModel.fromMap(Map<String, dynamic> map, String id) {
    return FuelSupplyEntryModel(
      id: id,
      date: map['date'] != null
          ? (map['date'] as Timestamp).toDate()
          : DateTime.now(),
      litersDelivered: (map['litersDelivered'] as num?)?.toDouble() ?? 0,
      supplierName: map['supplierName'] as String?,
      invoiceNumber: map['invoiceNumber'] as String?,
      pricePerLiter: (map['pricePerLiter'] as num?)?.toDouble(),
      notes: map['notes'] as String?,
      createdById: map['createdById'] as String? ?? '',
      createdByName: map['createdByName'] as String? ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      isValidated: map['isValidated'] as bool? ?? false,
      validatedAt: map['validatedAt'] != null
          ? (map['validatedAt'] as Timestamp).toDate()
          : null,
      validatedById: map['validatedById'] as String?,
      validatedByName: map['validatedByName'] as String?,
    );
  }

  final String id;
  final DateTime date;
  final double litersDelivered;
  final String? supplierName;
  final String? invoiceNumber;
  final double? pricePerLiter;
  final String? notes;
  final String createdById;
  final String createdByName;
  final DateTime createdAt;
  final bool isValidated;
  final DateTime? validatedAt;
  final String? validatedById;
  final String? validatedByName;

  double? get totalCost =>
      pricePerLiter != null ? litersDelivered * pricePerLiter! : null;

  String get displayDate =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  Map<String, dynamic> toMap() => {
        'date': Timestamp.fromDate(date),
        'litersDelivered': litersDelivered,
        if (supplierName != null) 'supplierName': supplierName,
        if (invoiceNumber != null) 'invoiceNumber': invoiceNumber,
        if (pricePerLiter != null) 'pricePerLiter': pricePerLiter,
        if (notes != null) 'notes': notes,
        'createdById': createdById,
        'createdByName': createdByName,
        'createdAt': FieldValue.serverTimestamp(),
        'isValidated': isValidated,
        if (validatedAt != null) 'validatedAt': Timestamp.fromDate(validatedAt!),
        if (validatedById != null) 'validatedById': validatedById,
        if (validatedByName != null) 'validatedByName': validatedByName,
      };
}
