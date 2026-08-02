import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/fuel_entry_model.dart';
import '../../../trucks/domain/models/truck_model.dart';

/// Repository pour la gestion des entrées de carburant
class FuelRepository {
  FuelRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Collection Firestore pour les entrées de carburant
  CollectionReference<Map<String, dynamic>> get _fuelCollection =>
      _firestore.collection('fuel_entries');

  /// Ajouter une entrée de carburant
  Future<FuelEntryModel> addFuelEntry({
    required String truckId,
    required String truckImmatriculation,
    required String truckFleetNumber,
    required double liters,
    required String addedBy,
    required String addedByName,
    String? truckBrand,
    String? truckModel,
    XFile? receiptPhoto,
    String? notes,
  }) async {
    try {
      String? receiptPhotoUrl;

      // Upload de la photo si fournie
      if (receiptPhoto != null) {
        receiptPhotoUrl = await _uploadReceiptPhoto(receiptPhoto, truckId);
      }

      final entry = FuelEntryModel(
        id: '', // Sera remplacé par l'ID Firestore
        truckId: truckId,
        truckImmatriculation: truckImmatriculation,
        truckFleetNumber: truckFleetNumber,
        liters: liters,
        addedBy: addedBy,
        addedByName: addedByName,
        receiptPhotoUrl: receiptPhotoUrl,
        notes: notes,
        truckBrand: truckBrand,
        truckModel: truckModel,
        createdAt: DateTime.now(),
      );

      final docRef = await _fuelCollection.add(entry.toMap());

      return entry.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload de la photo du bon de carburant
  Future<String> _uploadReceiptPhoto(XFile photo, String truckId) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('fuel_receipts/$truckId/$timestamp.jpg');

    final bytes = await photo.readAsBytes();
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Récupérer toutes les entrées de carburant pour un véhicule
  Future<List<FuelEntryModel>> getFuelEntriesForTruck(String truckId) async {
    try {
      final querySnapshot = await _fuelCollection
          .where('truckId', isEqualTo: truckId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => FuelEntryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les entrées récentes (pour le pompiste)
  Future<List<FuelEntryModel>> getRecentFuelEntries({
    required String addedBy,
    int limit = 10,
  }) async {
    try {
      final querySnapshot = await _fuelCollection
          .where('addedBy', isEqualTo: addedBy)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return querySnapshot.docs
          .map((doc) => FuelEntryModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Écouter les entrées de carburant en temps réel pour un véhicule
  Stream<List<FuelEntryModel>> watchFuelEntriesForTruck(String truckId) {
    return _fuelCollection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelEntryModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Récupérer le total de litres pour un véhicule
  Future<double> getTotalLitersForTruck(String truckId) async {
    try {
      final entries = await getFuelEntriesForTruck(truckId);
      return entries.fold<double>(0, (total, entry) => total + entry.liters);
    } catch (e) {
      rethrow;
    }
  }

  /// Rechercher un véhicule par immatriculation et numéro de flotte
  Future<TruckModel?> findTruckByImmatriculationAndFleetNumber({
    required String immatriculation,
    required String fleetNumber,
  }) async {
    try {
      // Normaliser les valeurs de recherche
      final normalizedImmat = immatriculation.trim().toUpperCase();
      final normalizedFleet = fleetNumber.trim().toUpperCase();

      final querySnapshot = await _firestore
          .collection('trucks')
          .where('immatriculation', isEqualTo: normalizedImmat)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return null;
      }

      final doc = querySnapshot.docs.first;
      final truck = TruckModel.fromMap(doc.data(), doc.id);

      // Vérifier si le numéro de flotte correspond
      if (truck.numeroInterneFlotte.toUpperCase() != normalizedFleet) {
        return null;
      }

      return truck;
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer une entrée de carburant
  Future<void> deleteFuelEntry(String entryId) async {
    try {
      await _fuelCollection.doc(entryId).delete();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les statistiques de carburant pour un véhicule
  Future<Map<String, dynamic>> getFuelStatsForTruck(String truckId) async {
    try {
      final entries = await getFuelEntriesForTruck(truckId);

      if (entries.isEmpty) {
        return {
          'totalLiters': 0.0,
          'totalEntries': 0,
          'averageLiters': 0.0,
          'lastEntry': null,
        };
      }

      final totalLiters = entries.fold<double>(0, (total, e) => total + e.liters);
      final averageLiters = totalLiters / entries.length;

      return {
        'totalLiters': totalLiters,
        'totalEntries': entries.length,
        'averageLiters': averageLiters,
        'lastEntry': entries.first,
      };
    } catch (e) {
      rethrow;
    }
  }
}
