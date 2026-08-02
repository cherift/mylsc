import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/fuel_request_model.dart';

/// Repository pour la gestion des demandes de carburant
class FuelRequestRepository {
  FuelRequestRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requestCollection =>
      _firestore.collection('fuel_requests');

  // ── Création ──

  /// Créer une demande de carburant
  Future<FuelRequestModel> createRequest({
    required String truckId,
    required String truckImmatriculation,
    required String requestedBy,
    required String requestedByName,
    double requestedLiters = 0,
    String? truckFleetNumber,
    String? driverId,
    String? driverName,
    String? reason,
    String? fleetId,
    String? shiftId,
  }) async {
    final code = (Random().nextInt(900000) + 100000).toString();
    final request = FuelRequestModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      truckFleetNumber: truckFleetNumber,
      driverId: driverId,
      driverName: driverName,
      requestedBy: requestedBy,
      requestedByName: requestedByName,
      requestedLiters: requestedLiters,
      reason: reason,
      status: FuelRequestStatus.pending,
      createdAt: DateTime.now(),
      fleetId: fleetId,
      shiftId: shiftId,
      verificationCode: code,
    );

    final docRef = await _requestCollection.add(request.toMap());
    return request.copyWith(id: docRef.id);
  }

  // ── Exécution (pompiste) ──

  /// Marquer une demande comme servie
  /// Auto-valide si le litrage servi correspond exactement au litrage demandé
  Future<void> fulfillRequest({
    required String requestId,
    required String fulfilledBy,
    required String fulfilledByName,
    required double fulfilledLiters,
    String? fuelEntryId,
    String? receiptPhotoUrl,
    String? receiptNumber,
    String? observation,
  }) async {
    // Lire la demande pour obtenir le litrage demandé
    final doc = await _requestCollection.doc(requestId).get();
    final requestedLiters =
        (doc.data()?['requestedLiters'] as num?)?.toDouble() ?? 0;

    final now = Timestamp.fromDate(DateTime.now());
    final updateData = <String, dynamic>{
      'fulfilledBy': fulfilledBy,
      'fulfilledByName': fulfilledByName,
      'fulfilledAt': now,
      'fulfilledLiters': fulfilledLiters,
      'fuelEntryId': fuelEntryId,
      'receiptPhotoUrl': receiptPhotoUrl,
      'receiptNumber': receiptNumber,
      'observation': observation,
    };

    // Auto-validation si le litrage servi == litrage demandé
    if (fulfilledLiters == requestedLiters) {
      updateData['status'] = 'validated';
      updateData['validatedBy'] = 'system';
      updateData['validatedByName'] = 'Auto';
      updateData['validatedAt'] = now;
      updateData['isAutoValidated'] = true;
    } else {
      updateData['status'] = 'fulfilled';
      updateData['isAutoValidated'] = false;
    }

    await _requestCollection.doc(requestId).update(updateData);
  }

  // ── Validation (superviseur) ──

  /// Valider une demande servie
  Future<void> validateFulfilledRequest({
    required String requestId,
    required String validatedBy,
    required String validatedByName,
  }) async {
    await _requestCollection.doc(requestId).update({
      'status': 'validated',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Contester une demande servie
  Future<void> disputeFulfilledRequest({
    required String requestId,
    required String validatedBy,
    required String validatedByName,
    required String disputeReason,
  }) async {
    await _requestCollection.doc(requestId).update({
      'status': 'disputed',
      'validatedBy': validatedBy,
      'validatedByName': validatedByName,
      'validatedAt': Timestamp.fromDate(DateTime.now()),
      'disputeReason': disputeReason,
    });
  }

  /// Annuler une demande (seulement si status = pending)
  Future<void> cancelRequest({
    required String requestId,
    required String cancelledBy,
    required String cancelledByName,
  }) async {
    await _requestCollection.doc(requestId).update({
      'status': 'cancelled',
      'cancelledBy': cancelledBy,
      'cancelledByName': cancelledByName,
      'cancelledAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Résoudre une demande contestée (responsable opérations)
  /// Si [validate] est true, la demande passe en 'validated', sinon en 'rejected'
  Future<void> resolveDisputedRequest({
    required String requestId,
    required String resolvedBy,
    required String resolvedByName,
    required bool validate,
    String? resolutionNote,
  }) async {
    final now = Timestamp.fromDate(DateTime.now());
    final updateData = <String, dynamic>{
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'resolvedAt': now,
      'resolutionNote': resolutionNote,
    };

    if (validate) {
      updateData['status'] = 'validated';
      updateData['validatedBy'] = resolvedBy;
      updateData['validatedByName'] = resolvedByName;
      updateData['validatedAt'] = now;
    } else {
      updateData['status'] = 'rejected';
      updateData['rejectionReason'] = resolutionNote;
    }

    await _requestCollection.doc(requestId).update(updateData);
  }

  /// Rechercher une demande approuvée par immatriculation et code de vérification
  Future<FuelRequestModel?> findApprovedRequestByImmatriculationAndCode({
    required String immatriculation,
    required String verificationCode,
  }) async {
    final snapshot = await _requestCollection
        .where('verificationCode', isEqualTo: verificationCode)
        .get();

    final matches = snapshot.docs
        .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
        .where((r) =>
            r.status == FuelRequestStatus.pending &&
            r.truckImmatriculation.toLowerCase() ==
                immatriculation.toLowerCase())
        .toList();

    return matches.isEmpty ? null : matches.first;
  }

  /// Rechercher n'importe quelle demande par immatriculation et code
  /// (sans filtre de statut) — pour afficher un message d'erreur précis
  Future<FuelRequestModel?> findRequestByImmatriculationAndCode({
    required String immatriculation,
    required String verificationCode,
  }) async {
    final snapshot = await _requestCollection
        .where('verificationCode', isEqualTo: verificationCode)
        .get();

    final matches = snapshot.docs
        .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
        .where((r) =>
            r.truckImmatriculation.toLowerCase() ==
            immatriculation.toLowerCase())
        .toList();

    return matches.isEmpty ? null : matches.first;
  }

  // ── Lecture ──

  /// Récupérer une demande par ID
  Future<FuelRequestModel?> getRequest(String requestId) async {
    final doc = await _requestCollection.doc(requestId).get();
    if (!doc.exists) return null;
    return FuelRequestModel.fromMap(doc.data()!, doc.id);
  }

  /// Récupérer les demandes par statut
  Future<List<FuelRequestModel>> getRequestsByStatus(
      FuelRequestStatus status) async {
    final snapshot = await _requestCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupérer les demandes d'un utilisateur
  Future<List<FuelRequestModel>> getRequestsByUser(String userId) async {
    final snapshot = await _requestCollection
        .where('requestedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Streams temps réel ──

  /// Écouter les demandes en attente
  Stream<List<FuelRequestModel>> watchPendingRequests() {
    return _requestCollection
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter toutes les demandes (pour le chef ravitaillement)
  Stream<List<FuelRequestModel>> watchAllRequests() {
    return _requestCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les demandes d'une flotte
  Stream<List<FuelRequestModel>> watchRequestsByFleet(String fleetId) {
    return _requestCollection
        .where('fleetId', isEqualTo: fleetId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les demandes d'un utilisateur
  Stream<List<FuelRequestModel>> watchRequestsByUser(String userId) {
    return _requestCollection
        .where('requestedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les demandes contestées
  Stream<List<FuelRequestModel>> watchDisputedRequests() {
    return _requestCollection
        .where('status', isEqualTo: 'disputed')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les demandes servies par un pompiste
  Stream<List<FuelRequestModel>> watchRequestsFulfilledBy(String userId) {
    return _requestCollection
        .where('fulfilledBy', isEqualTo: userId)
        .orderBy('fulfilledAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
