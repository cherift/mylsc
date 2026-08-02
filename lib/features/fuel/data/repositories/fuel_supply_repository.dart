import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/fuel_supply_entry_model.dart';

/// Repository pour les entrées de ravitaillement du stock global.
class FuelSupplyRepository {
  final CollectionReference _col =
      FirebaseFirestore.instance.collection('fuel_supply_entries');

  /// Stream en temps réel de toutes les entrées (ordre anti-chronologique).
  Stream<List<FuelSupplyEntryModel>> watchAll() {
    return _col
        .orderBy('date', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => FuelSupplyEntryModel.fromMap(
                d.data()! as Map<String, dynamic>, d.id))
            .toList());
  }

  /// Ajoute une nouvelle entrée de ravitaillement.
  Future<void> addEntry({
    required DateTime date,
    required double litersDelivered,
    required String createdById,
    required String createdByName,
    String? supplierName,
    String? invoiceNumber,
    double? pricePerLiter,
    String? notes,
  }) async {
    await _col.add({
      'date': Timestamp.fromDate(date),
      'litersDelivered': litersDelivered,
      if (supplierName != null && supplierName.isNotEmpty)
        'supplierName': supplierName,
      if (invoiceNumber != null && invoiceNumber.isNotEmpty)
        'invoiceNumber': invoiceNumber,
      if (pricePerLiter != null) 'pricePerLiter': pricePerLiter,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      'createdById': createdById,
      'createdByName': createdByName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Valide une entrée (verrouille la suppression).
  Future<void> validateEntry(
    String id, {
    required String validatedById,
    required String validatedByName,
  }) async {
    await _col.doc(id).update({
      'isValidated': true,
      'validatedAt': FieldValue.serverTimestamp(),
      'validatedById': validatedById,
      'validatedByName': validatedByName,
    });
  }

  /// Supprime une entrée par son id (échoue si déjà validée).
  Future<void> deleteEntry(String id) async {
    final doc = await _col.doc(id).get();
    if (doc.exists) {
      final isValidated =
          (doc.data()! as Map<String, dynamic>)['isValidated'] as bool? ??
              false;
      if (isValidated) {
        throw Exception('validated');
      }
    }
    await _col.doc(id).delete();
  }
}
