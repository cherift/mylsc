import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/weighing_record_model.dart';

/// Repository pour la gestion des pesées
class WeighingRepository {
  WeighingRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('weighings');

  // ── Création ──

  /// Enregistrer une pesée
  Future<WeighingRecordModel> createRecord({
    required String truckId,
    required String truckImmatriculation,
    required WeighingLocation location,
    required double emptyWeight,
    required double loadedWeight,
    required String weighedBy,
    required String weighedByName,
    String? truckFleetNumber,
    String? driverId,
    String? driverName,
    String? shiftId,
    String? ticketNumber,
    String? notes,
    List<String>? photoUrls,
    String? weighedByMatricule,
    String? driverMatricule,
  }) async {
    final record = WeighingRecordModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      truckFleetNumber: truckFleetNumber,
      location: location,
      weight: loadedWeight - emptyWeight,
      emptyWeight: emptyWeight,
      loadedWeight: loadedWeight,
      driverId: driverId,
      driverName: driverName,
      shiftId: shiftId,
      ticketNumber: ticketNumber,
      weighedBy: weighedBy,
      weighedByName: weighedByName,
      status: WeighingStatus.recorded,
      createdAt: DateTime.now(),
      notes: notes,
      photoUrls: photoUrls,
      weighedByMatricule: weighedByMatricule,
      driverMatricule: driverMatricule,
    );

    final docRef = await _collection.add(record.toMap());
    return record.copyWith(id: docRef.id);
  }

  /// Enregistrer une pesée partielle (premier poids seulement)
  Future<WeighingRecordModel> createPartialRecord({
    required String truckId,
    required String truckImmatriculation,
    required WeighingLocation location,
    required double firstWeight,
    required String weighedBy,
    required String weighedByName,
    required String ticketNumber,
    String? truckFleetNumber,
    String? driverId,
    String? driverName,
    String? shiftId,
    String? weighedByMatricule,
  }) async {
    final isMine = location == WeighingLocation.mine;
    final record = WeighingRecordModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      truckFleetNumber: truckFleetNumber,
      location: location,
      weight: 0,
      emptyWeight: isMine ? firstWeight : null,
      loadedWeight: isMine ? null : firstWeight,
      driverId: driverId,
      driverName: driverName,
      shiftId: shiftId,
      ticketNumber: ticketNumber,
      weighedBy: weighedBy,
      weighedByName: weighedByName,
      status: WeighingStatus.pending,
      createdAt: DateTime.now(),
      weighedByMatricule: weighedByMatricule,
    );
    final docRef = await _collection.add(record.toMap());
    return record.copyWith(id: docRef.id);
  }

  /// Finaliser une pesée en attente avec le second poids.
  /// Lance une exception si [exitTicketNumber] ne correspond pas au ticket d'entrée.
  Future<void> completeRecord({
    required String recordId,
    required WeighingLocation location,
    required double secondWeight,
    required String exitTicketNumber,
    String? notes,
    List<String>? photoUrls,
  }) async {
    final doc = await _collection.doc(recordId).get();
    if (!doc.exists) throw Exception('Record not found');
    final existing = WeighingRecordModel.fromMap(doc.data()!, doc.id);

    if (existing.ticketNumber != null &&
        existing.ticketNumber!.isNotEmpty &&
        exitTicketNumber.trim() != existing.ticketNumber!.trim()) {
      throw Exception('ticket_mismatch');
    }

    final isMine = location == WeighingLocation.mine;
    final emptyWeight = isMine ? existing.emptyWeight! : secondWeight;
    final loadedWeight = isMine ? secondWeight : existing.loadedWeight!;
    final netWeight = loadedWeight - emptyWeight;

    final updates = <String, dynamic>{
      'emptyWeight': emptyWeight,
      'loadedWeight': loadedWeight,
      'weight': netWeight,
      'status': 'recorded',
      'ticketNumber': exitTicketNumber.trim(),
    };
    if (notes != null && notes.isNotEmpty) updates['notes'] = notes;
    if (photoUrls != null) updates['photoUrls'] = photoUrls;

    await _collection.doc(recordId).update(updates);
  }

  // ── Événements Stockage ──

  CollectionReference<Map<String, dynamic>> get _storageEventsCollection =>
      _firestore.collection('storage_events');

  Future<void> createStorageEvent({
    required String truckId,
    required String truckImmatriculation,
    required String? fleetId,
    required String recordedBy,
    required String recordedByName,
    String? weighingId,
    String? ticketNumber,
    String eventType = 'unloaded',
  }) async {
    if (fleetId == null) return;
    await _storageEventsCollection.add({
      'truckId': truckId,
      'truckImmatriculation': truckImmatriculation,
      'fleetId': fleetId,
      'weighingId': weighingId,
      'ticketNumber': ticketNumber,
      'eventType': eventType,
      'recordedBy': recordedBy,
      'recordedByName': recordedByName,
      'createdAt': Timestamp.fromDate(DateTime.now()),
      'isRead': false,
    });
  }

  Stream<List<Map<String, dynamic>>> watchUnreadStorageEvents(String fleetId) {
    return _storageEventsCollection
        .where('fleetId', isEqualTo: fleetId)
        .where('isRead', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }

  Future<void> markStorageEventRead(String eventId) async {
    await _storageEventsCollection.doc(eventId).update({'isRead': true});
  }

  Future<void> markAllStorageEventsRead(String fleetId) async {
    final docs = await _storageEventsCollection
        .where('fleetId', isEqualTo: fleetId)
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _firestore.batch();
    for (final doc in docs.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ── Validation / Rejet ──

  /// Valider une pesée
  Future<void> validateRecord({
    required String recordId,
    required String validatedBy,
    required String validatedByName,
  }) async {
    await _collection.doc(recordId).update({
      'status': 'validated',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Rejeter une pesée
  Future<void> rejectRecord({
    required String recordId,
    required String validatedBy,
    required String validatedByName,
    String? rejectionReason,
  }) async {
    await _collection.doc(recordId).update({
      'status': 'rejected',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
      'rejectionReason': rejectionReason,
    });
  }

  /// Marquer une pesée mine comme chargée
  Future<void> markAsLoaded({
    required String recordId,
    required String chargedBy,
    required String chargedByName,
  }) async {
    await _collection.doc(recordId).update({
      'status': 'loaded',
      'chargedBy': chargedBy,
      'chargedByName': chargedByName,
      'chargedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Marquer une pesée port comme déchargée
  Future<void> markAsUnloaded({
    required String recordId,
    required String dischargedBy,
    required String dischargedByName,
  }) async {
    await _collection.doc(recordId).update({
      'status': 'unloaded',
      'dischargedBy': dischargedBy,
      'dischargedByName': dischargedByName,
      'dischargedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Lecture ──

  /// Récupérer une pesée par ID
  Future<WeighingRecordModel?> getRecord(String recordId) async {
    final doc = await _collection.doc(recordId).get();
    if (!doc.exists) return null;
    return WeighingRecordModel.fromMap(doc.data()!, doc.id);
  }

  /// Récupérer les pesées par lieu
  Future<List<WeighingRecordModel>> getRecordsByLocation(
      WeighingLocation location) async {
    final snapshot = await _collection
        .where('location', isEqualTo: location.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupérer les pesées d'un camion
  Future<List<WeighingRecordModel>> getRecordsByTruck(String truckId) async {
    final snapshot = await _collection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Streams temps réel ──

  /// Écouter les pesées par lieu (mine ou port)
  Stream<List<WeighingRecordModel>> watchRecordsByLocation(
      WeighingLocation location) {
    return _collection
        .where('location', isEqualTo: location.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter toutes les pesées
  Stream<List<WeighingRecordModel>> watchAllRecords() {
    return _collection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pesées d'un chauffeur
  Stream<List<WeighingRecordModel>> watchRecordsByDriver(String driverId) {
    return _collection
        .where('driverId', isEqualTo: driverId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pesées d'un utilisateur
  Stream<List<WeighingRecordModel>> watchRecordsByUser(String userId) {
    return _collection
        .where('weighedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pesées en attente d'un utilisateur
  Stream<List<WeighingRecordModel>> watchPendingByUser(String userId) {
    return _collection
        .where('weighedBy', isEqualTo: userId)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pesées enregistrées (status=recorded) par lieu
  Stream<List<WeighingRecordModel>> watchRecordedByLocation(
      WeighingLocation location) {
    return _collection
        .where('location', isEqualTo: location.name)
        .where('status', isEqualTo: 'recorded')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
