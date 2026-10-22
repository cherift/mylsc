import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/weighing_edit_model.dart';
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
    String? clientId,
    String? clientName,
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
      clientId: clientId,
      clientName: clientName,
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
    String? clientId,
    String? clientName,
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
      clientId: clientId,
      clientName: clientName,
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
    String? clientId,
    String? clientName,
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
    // Le client saisi à l'entrée est conservé ; ne compléter que s'il manque
    if (existing.clientId == null && clientId != null) {
      updates['clientId'] = clientId;
      updates['clientName'] = clientName;
    }

    await _collection.doc(recordId).update(updates);
  }

  // ── Correction (T.38) ──

  /// Corrige une pesée et trace l'opération dans `weighings/{id}/edits`.
  /// Seuls les champs réellement modifiés sont enregistrés ; le poids net
  /// est recalculé si les deux pesées sont connues.
  /// Retourne false si aucun champ n'a changé.
  Future<bool> correctRecord({
    required WeighingRecordModel original,
    required String editedBy,
    required String editedByName,
    required String reason,
    double? emptyWeight,
    double? loadedWeight,
    String? ticketNumber,
    String? clientId,
    String? clientName,
    String? notes,
  }) async {
    final changes = <String, ({Object? old, Object? value})>{};
    final updates = <String, dynamic>{};

    void track(String field, Object? oldValue, Object? newValue) {
      if (newValue == null || newValue == oldValue) return;
      changes[field] = (old: oldValue, value: newValue);
      updates[field] = newValue;
    }

    track('emptyWeight', original.emptyWeight, emptyWeight);
    track('loadedWeight', original.loadedWeight, loadedWeight);
    track('ticketNumber', original.ticketNumber, ticketNumber?.trim());
    track('clientId', original.clientId, clientId);
    if (updates.containsKey('clientId')) {
      updates['clientName'] = clientName;
      changes['clientName'] = (old: original.clientName, value: clientName);
    }
    track('notes', original.notes ?? '', notes?.trim());

    if (changes.isEmpty) return false;

    // Recalcul du poids net si les deux pesées sont connues
    final newEmpty = emptyWeight ?? original.emptyWeight;
    final newLoaded = loadedWeight ?? original.loadedWeight;
    if (newEmpty != null && newLoaded != null) {
      final newNet = newLoaded - newEmpty;
      if (newNet != original.weight) {
        updates['weight'] = newNet;
        changes['weight'] = (old: original.weight, value: newNet);
      }
    }

    final now = DateTime.now();
    updates['lastEditedBy'] = editedBy;
    updates['lastEditedByName'] = editedByName;
    updates['lastEditedAt'] = Timestamp.fromDate(now);

    final docRef = _collection.doc(original.id);
    final edit = WeighingEditModel(
      id: '',
      editedBy: editedBy,
      editedByName: editedByName,
      editedAt: now,
      reason: reason.trim(),
      changes: changes,
    );

    final batch = _firestore.batch()
      ..update(docRef, updates)
      ..set(docRef.collection('edits').doc(), edit.toMap());
    await batch.commit();
    return true;
  }

  /// Suivi en temps réel d'une pesée
  Stream<WeighingRecordModel?> watchRecord(String recordId) {
    return _collection.doc(recordId).snapshots().map((doc) =>
        doc.exists ? WeighingRecordModel.fromMap(doc.data()!, doc.id) : null);
  }

  /// Historique des corrections d'une pesée (plus récente d'abord)
  Stream<List<WeighingEditModel>> watchEdits(String recordId) {
    return _collection
        .doc(recordId)
        .collection('edits')
        .orderBy('editedAt', descending: true)
        .snapshots()
        .map((s) => s.docs
            .map((d) => WeighingEditModel.fromMap(d.data(), d.id))
            .toList());
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
