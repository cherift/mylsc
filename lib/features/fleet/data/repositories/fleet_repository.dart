import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/fleet_model.dart';

class FleetRepository {
  FleetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _fleetCollection =>
      _firestore.collection('fleets');

  // ============ CREATE ============

  Future<FleetModel> createFleet(FleetModel fleet) async {
    final docRef = await _fleetCollection.add(fleet.toMap());
    return fleet.copyWith(id: docRef.id);
  }

  // ============ READ ============

  Future<FleetModel?> getFleetById(String id) async {
    final doc = await _fleetCollection.doc(id).get();
    if (!doc.exists) return null;
    return FleetModel.fromMap(doc.data()!, doc.id);
  }

  // ============ UPDATE ============

  Future<void> updateFleet(FleetModel fleet) async {
    await _fleetCollection.doc(fleet.id).update(fleet.toMap());
  }

  Future<void> deactivateFleet(String fleetId) async {
    await _fleetCollection.doc(fleetId).update({'isActive': false});
  }

  // ============ DELETE ============

  /// Vérifie si la flotte a des camions ou chauffeurs encore assignés.
  Future<String?> checkFleetDependencies(String fleetId) async {
    final trucks = await _firestore
        .collection('trucks')
        .where('fleetId', isEqualTo: fleetId)
        .limit(1)
        .get();
    if (trucks.docs.isNotEmpty) return 'trucks';

    final drivers = await _firestore
        .collection('users')
        .where('fleetId', isEqualTo: fleetId)
        .limit(1)
        .get();
    if (drivers.docs.isNotEmpty) return 'drivers';

    return null;
  }

  /// Supprime la flotte (désactivation logique).
  Future<void> deleteFleet(String fleetId) async {
    await _fleetCollection.doc(fleetId).update({'isActive': false});
  }

  // ============ STREAMS ============

  Stream<List<FleetModel>> watchAllFleets() {
    return _fleetCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FleetModel.fromMap(doc.data(), doc.id))
            .where((fleet) => fleet.isActive)
            .toList());
  }

  Stream<List<FleetModel>> watchFleetsBySupervisor(String supervisorId) {
    return _fleetCollection
        .where('supervisorId', isEqualTo: supervisorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FleetModel.fromMap(doc.data(), doc.id))
            .where((fleet) => fleet.isActive)
            .toList());
  }

  // ============ ASSIGN / UNASSIGN ============

  Future<void> assignTruckToFleet(String truckId, String fleetId) async {
    await _firestore.collection('trucks').doc(truckId).update({
      'fleetId': fleetId,
    });
  }

  Future<void> unassignTruckFromFleet(String truckId) async {
    await _firestore.collection('trucks').doc(truckId).update({
      'fleetId': null,
    });
  }

  Future<void> assignDriverToFleet(String userId, String fleetId) async {
    await _firestore.collection('users').doc(userId).update({
      'fleetId': fleetId,
    });
  }

  Future<void> unassignDriverFromFleet(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'fleetId': null,
    });
  }
}
