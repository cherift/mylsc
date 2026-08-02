import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/driver_assignment_model.dart';
import '../../domain/models/shift_model.dart';

/// Repository pour la gestion des affectations et vacations
class ShiftRepository {
  ShiftRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _assignmentCollection =>
      _firestore.collection('driver_assignments');

  CollectionReference<Map<String, dynamic>> get _shiftCollection =>
      _firestore.collection('shifts');

  // ── Affectations ──

  /// Affecter un chauffeur à un camion
  Future<DriverAssignmentModel> assignDriver({
    required String truckId,
    required String truckImmatriculation,
    required String driverId,
    required String driverName,
    required String assignedBy,
    required String assignedByName,
    bool isPrimary = true,
    DriverRank driverRank = DriverRank.principal,
  }) async {
    final driverActiveAssignments = await _assignmentCollection
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in driverActiveAssignments.docs) {
      final existingTruckId = doc.data()['truckId'] as String?;
      final existingTruckImmat =
          doc.data()['truckImmatriculation'] as String? ?? '';
      if (existingTruckId != null && existingTruckId != truckId) {
        throw Exception('DRIVER_ALREADY_ASSIGNED:$existingTruckImmat');
      }
    }

    // Désactiver l'affectation active précédente du même camion si primaire
    if (isPrimary) {
      final existing = await _assignmentCollection
          .where('truckId', isEqualTo: truckId)
          .where('isActive', isEqualTo: true)
          .where('isPrimary', isEqualTo: true)
          .get();

      for (final doc in existing.docs) {
        await doc.reference.update({
          'isActive': false,
          'unassignedAt': Timestamp.fromDate(DateTime.now()),
        });
      }
    }

    final assignment = DriverAssignmentModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      driverId: driverId,
      driverName: driverName,
      assignedBy: assignedBy,
      assignedByName: assignedByName,
      isPrimary: isPrimary,
      driverRank: driverRank,
      assignedAt: DateTime.now(),
    );

    final docRef = await _assignmentCollection.add(assignment.toMap());
    return assignment.copyWith(id: docRef.id);
  }

  /// Désaffecter un chauffeur
  Future<void> unassignDriver(String assignmentId) async {
    await _assignmentCollection.doc(assignmentId).update({
      'isActive': false,
      'unassignedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Récupérer l'affectation active d'un camion
  Future<DriverAssignmentModel?> getActiveAssignmentForTruck(
      String truckId) async {
    final snapshot = await _assignmentCollection
        .where('truckId', isEqualTo: truckId)
        .where('isActive', isEqualTo: true)
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return DriverAssignmentModel.fromMap(doc.data(), doc.id);
  }

  /// Récupérer les affectations actives d'un chauffeur
  Future<List<DriverAssignmentModel>> getActiveAssignmentsForDriver(
      String driverId) async {
    final snapshot = await _assignmentCollection
        .where('driverId', isEqualTo: driverId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs
        .map((doc) => DriverAssignmentModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Écouter les affectations actives en temps réel
  Stream<List<DriverAssignmentModel>> watchActiveAssignments() {
    return _assignmentCollection
        .where('isActive', isEqualTo: true)
        .orderBy('assignedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverAssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les affectations actives d'un camion
  Stream<List<DriverAssignmentModel>> watchAssignmentsForTruck(
      String truckId) {
    return _assignmentCollection
        .where('truckId', isEqualTo: truckId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DriverAssignmentModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // ── Vacations (Shifts) ──

  /// Démarrer une vacation (prise de fonction)
  Future<ShiftModel> startShift({
    required String truckId,
    required String truckImmatriculation,
    required String driverId,
    required String driverName,
    String? startedBy,
    String? startedByName,
  }) async {
    // Terminer la vacation active précédente du même chauffeur
    final existing = await _shiftCollection
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in existing.docs) {
      await doc.reference.update({
        'status': 'ended',
        'endTime': Timestamp.fromDate(DateTime.now()),
      });
    }

    final now = DateTime.now();
    final shift = ShiftModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      driverId: driverId,
      driverName: driverName,
      startedBy: startedBy,
      startedByName: startedByName,
      startTime: now,
      createdAt: now,
    );

    final docRef = await _shiftCollection.add(shift.toMap());
    return shift.copyWith(id: docRef.id);
  }

  /// Terminer une vacation.
  /// le superviseur doit explicitement désaffecter le chauffeur si nécessaire.
  Future<void> endShift(
    String shiftId, {
    String? driverId,
    String? truckId,
  }) async {
    await _shiftCollection.doc(shiftId).update({
      'status': 'ended',
      'endTime': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Récupérer la vacation active d'un chauffeur
  Future<ShiftModel?> getActiveShiftForDriver(String driverId) async {
    final snapshot = await _shiftCollection
        .where('driverId', isEqualTo: driverId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ShiftModel.fromMap(doc.data(), doc.id);
  }

  /// Récupérer la vacation active sur un camion
  Future<ShiftModel?> getActiveShiftForTruck(String truckId) async {
    final snapshot = await _shiftCollection
        .where('truckId', isEqualTo: truckId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return ShiftModel.fromMap(doc.data(), doc.id);
  }

  /// Écouter les vacations actives en temps réel
  Stream<List<ShiftModel>> watchActiveShifts() {
    return _shiftCollection
        .where('status', isEqualTo: 'active')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les vacations d'un chauffeur
  Stream<List<ShiftModel>> watchShiftsForDriver(String driverId) {
    return _shiftCollection
        .where('driverId', isEqualTo: driverId)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Récupérer l'historique des vacations d'un camion
  Future<List<ShiftModel>> getShiftHistoryForTruck(String truckId) async {
    final snapshot = await _shiftCollection
        .where('truckId', isEqualTo: truckId)
        .orderBy('startTime', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Stream<List<ShiftModel>> watchAllShifts() {
    return _shiftCollection
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les vacations du jour (filtre date côté Firestore — pas d'index composite requis)
  Stream<List<ShiftModel>> watchTodayShifts() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return _shiftCollection
        .where('startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter toutes les vacations des camions d'une flotte (actives + terminées)
  Stream<List<ShiftModel>> watchShiftsForTruckIds(List<String> truckIds) {
    if (truckIds.isEmpty) return Stream.value([]);

    // Firestore whereIn limité à 30 éléments, on découpe si nécessaire
    if (truckIds.length <= 30) {
      return _shiftCollection
          .where('truckId', whereIn: truckIds)
          .orderBy('startTime', descending: true)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
              .toList());
    }

    // Pour plus de 30 camions, on combine les streams
    final chunks = <List<String>>[];
    for (var i = 0; i < truckIds.length; i += 30) {
      chunks.add(truckIds.sublist(
          i, i + 30 > truckIds.length ? truckIds.length : i + 30));
    }

    final streams = chunks.map((chunk) => _shiftCollection
        .where('truckId', whereIn: chunk)
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShiftModel.fromMap(doc.data(), doc.id))
            .toList()));

    return streams.reduce((combined, stream) {
      return combined.asyncExpand((list1) {
        return stream.map((list2) {
          final merged = [...list1, ...list2];
          merged.sort((a, b) => b.startTime.compareTo(a.startTime));
          return merged;
        });
      });
    });
  }
}
