import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/trip_model.dart';

/// Repository pour la gestion des rotations
class TripRepository {
  TripRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('trips');

  // ── Création ──

  /// Créer une rotation
  Future<TripModel> createTrip({
    required String truckId,
    required String truckImmatriculation,
    required String driverId,
    required String driverName,
    String? truckFleetNumber,
    String? shiftId,
    String? mineWeighingId,
    double? mineWeight,
    DateTime? departureTime,
    String? notes,
  }) async {
    final trip = TripModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      truckFleetNumber: truckFleetNumber,
      driverId: driverId,
      driverName: driverName,
      shiftId: shiftId,
      mineWeighingId: mineWeighingId,
      mineWeight: mineWeight,
      departureTime: departureTime ?? DateTime.now(),
      status: TripStatus.inProgress,
      createdAt: DateTime.now(),
      notes: notes,
    );

    final docRef = await _collection.add(trip.toMap());
    return trip.copyWith(id: docRef.id);
  }

  // ── Mise à jour ──

  /// Enregistrer l'arrivée au port avec pesée
  Future<void> recordPortArrival({
    required String tripId,
    required String portWeighingId,
    required double portWeight,
  }) async {
    await _collection.doc(tripId).update({
      'portWeighingId': portWeighingId,
      'portWeight': portWeight,
      'arrivalTime': Timestamp.fromDate(DateTime.now()),
      'status': 'pendingValidation',
    });
  }

  /// Enregistrer le retour
  Future<void> recordReturn({
    required String tripId,
  }) async {
    await _collection.doc(tripId).update({
      'returnTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Valider une rotation
  Future<void> validateTrip({
    required String tripId,
    required String validatedBy,
    required String validatedByName,
  }) async {
    await _collection.doc(tripId).update({
      'status': 'validated',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Rejeter une rotation
  Future<void> rejectTrip({
    required String tripId,
    required String validatedBy,
    required String validatedByName,
    String? rejectionReason,
  }) async {
    await _collection.doc(tripId).update({
      'status': 'rejected',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': rejectionReason,
    });
  }

  // ── Lecture ──

  /// Récupérer une rotation par ID
  Future<TripModel?> getTrip(String tripId) async {
    final doc = await _collection.doc(tripId).get();
    if (!doc.exists) return null;
    return TripModel.fromMap(doc.data()!, doc.id);
  }

  /// Récupérer les rotations par statut
  Future<List<TripModel>> getTripsByStatus(TripStatus status) async {
    final snapshot = await _collection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupérer les rotations d'un chauffeur
  Future<List<TripModel>> getTripsByDriver(String driverId) async {
    final snapshot = await _collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => TripModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Streams temps réel ──

  /// Écouter les rotations en attente de validation
  Stream<List<TripModel>> watchPendingValidation() {
    return _collection
        .where('status', isEqualTo: 'pendingValidation')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter toutes les rotations
  Stream<List<TripModel>> watchAllTrips() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les rotations d'un chauffeur
  Stream<List<TripModel>> watchTripsByDriver(String driverId) {
    return _collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les rotations d'un camion
  Stream<List<TripModel>> watchTripsByTruck(String truckId) {
    return _collection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TripModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
