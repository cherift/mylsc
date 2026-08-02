import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../domain/models/vehicle_inspection_model.dart';

/// Statut camion correspondant à un état constaté en inspection.
/// C'est ce statut qui est répercuté sur `trucks/{truckId}.statut` et donc
/// visible par tous les comptes (pointeurs, direction, vacation...).
extension VehicleStateToTruckStatus on VehicleState {
  TruckStatus get truckStatus {
    switch (this) {
      case VehicleState.bonEtat:
      case VehicleState.bonEtatAvecObservation:
        return TruckStatus.enService;
      case VehicleState.nonFonctionnel:
        return TruckStatus.enPanne;
      case VehicleState.accidente:
        return TruckStatus.immobilise;
      case VehicleState.autres:
        return TruckStatus.enMaintenance;
    }
  }
}

/// Repository pour la gestion des inspections de véhicules
class InspectionRepository {
  InspectionRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  /// Collection Firestore pour les inspections
  CollectionReference<Map<String, dynamic>> get _inspectionCollection =>
      _firestore.collection('inspections');

  /// Ajouter une inspection
  Future<VehicleInspectionModel> addInspection({
    required String truckId,
    required String inspectedBy,
    required VehicleState state,
    String? inspectedByName,
    String? observation,
    List<XFile>? photos,
  }) async {
    try {
      List<String>? photoUrls;

      if (photos != null && photos.isNotEmpty) {
        photoUrls = await _uploadPhotos(photos, truckId);
      }

      final inspection = VehicleInspectionModel(
        id: '',
        truckId: truckId,
        inspectedBy: inspectedBy,
        inspectedByName: inspectedByName,
        inspectionDate: DateTime.now(),
        state: state,
        observation: observation,
        photoUrls: photoUrls,
        createdAt: DateTime.now(),
      );

      final docRef = await _inspectionCollection.add(inspection.toJson());

      // Répercute le statut constaté sur le camion : c'est ce champ que
      // lisent le pointeur mine/port, la direction et la vue vacation.
      await _firestore.collection('trucks').doc(truckId).update({
        'statut': state.truckStatus.name,
        'updatedAt': Timestamp.now(),
      });

      return inspection.copyWith(id: docRef.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Upload des photos d'inspection
  Future<List<String>> _uploadPhotos(List<XFile> photos, String truckId) async {
    final urls = <String>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    for (var i = 0; i < photos.length; i++) {
      final ref = _storage
          .ref()
          .child('inspections/$truckId/${timestamp}_$i.jpg');
      final bytes = await photos[i].readAsBytes();
      await ref
          .putData(bytes, SettableMetadata(contentType: 'image/jpeg'))
          .timeout(const Duration(seconds: 30));
      final url = await ref.getDownloadURL();
      urls.add(url);
    }

    return urls;
  }

  /// Récupérer les inspections pour un véhicule
  Future<List<VehicleInspectionModel>> getInspectionsForTruck(
      String truckId) async {
    try {
      final querySnapshot = await _inspectionCollection
          .where('truckId', isEqualTo: truckId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleInspectionModel.fromJson(
              {...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les inspections faites par un superviseur
  Future<List<VehicleInspectionModel>> getInspectionsByUser(
      String userId) async {
    try {
      final querySnapshot = await _inspectionCollection
          .where('inspectedBy', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => VehicleInspectionModel.fromJson(
              {...doc.data(), 'id': doc.id}))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Écouter les inspections en temps réel pour un véhicule
  Stream<List<VehicleInspectionModel>> watchInspectionsForTruck(
      String truckId) {
    return _inspectionCollection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleInspectionModel.fromJson(
                {...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Écouter toutes les inspections en temps réel
  Stream<List<VehicleInspectionModel>> watchAllInspections() {
    return _inspectionCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => VehicleInspectionModel.fromJson(
                {...doc.data(), 'id': doc.id}))
            .toList());
  }

  /// Récupérer la dernière inspection d'un véhicule
  Future<VehicleInspectionModel?> getLastInspectionForTruck(
      String truckId) async {
    try {
      final querySnapshot = await _inspectionCollection
          .where('truckId', isEqualTo: truckId)
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) return null;

      final doc = querySnapshot.docs.first;
      return VehicleInspectionModel.fromJson({...doc.data(), 'id': doc.id});
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer une inspection
  Future<void> deleteInspection(String inspectionId) async {
    try {
      await _inspectionCollection.doc(inspectionId).delete();
    } catch (e) {
      rethrow;
    }
  }
}
