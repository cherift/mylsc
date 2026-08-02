import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/shift_repository.dart';
import '../../domain/models/driver_assignment_model.dart';
import '../../domain/models/shift_model.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../fleet/presentation/providers/fleet_providers.dart';

/// Provider pour le repository des shifts
final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository();
});

// ── Affectations ──

/// Provider pour l'affectation active d'un camion
final activeAssignmentForTruckProvider =
    FutureProvider.family<DriverAssignmentModel?, String>((ref, truckId) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getActiveAssignmentForTruck(truckId);
});

/// Provider pour les affectations actives d'un chauffeur
final activeAssignmentsForDriverProvider =
    FutureProvider.family<List<DriverAssignmentModel>, String>(
        (ref, driverId) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getActiveAssignmentsForDriver(driverId);
});

/// Provider stream pour les affectations actives
final activeAssignmentsStreamProvider =
    StreamProvider<List<DriverAssignmentModel>>((ref) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchActiveAssignments();
});

/// Provider stream pour les affectations d'un camion
final assignmentsForTruckStreamProvider =
    StreamProvider.family<List<DriverAssignmentModel>, String>((ref, truckId) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchAssignmentsForTruck(truckId);
});

// ── Vacations ──

/// Provider pour la vacation active d'un chauffeur
final activeShiftForDriverProvider =
    FutureProvider.family<ShiftModel?, String>((ref, driverId) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getActiveShiftForDriver(driverId);
});

/// Provider pour la vacation active sur un camion
final activeShiftForTruckProvider =
    FutureProvider.family<ShiftModel?, String>((ref, truckId) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getActiveShiftForTruck(truckId);
});

/// Provider stream pour les vacations actives
final activeShiftsStreamProvider = StreamProvider<List<ShiftModel>>((ref) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchActiveShifts();
});

final allShiftsStreamProvider = StreamProvider<List<ShiftModel>>((ref) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchAllShifts();
});

/// Provider stream pour les vacations du jour uniquement (filtre Firestore côté serveur)
final todayShiftsStreamProvider = StreamProvider<List<ShiftModel>>((ref) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchTodayShifts();
});

/// Provider stream pour les vacations d'un chauffeur
final shiftsForDriverStreamProvider =
    StreamProvider.family<List<ShiftModel>, String>((ref, driverId) {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchShiftsForDriver(driverId);
});

/// Provider pour l'historique des vacations d'un camion
final shiftHistoryForTruckProvider =
    FutureProvider.family<List<ShiftModel>, String>((ref, truckId) async {
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.getShiftHistoryForTruck(truckId);
});

/// Provider stream pour toutes les vacations des camions d'une flotte
final shiftsForFleetProvider =
    StreamProvider.family<List<ShiftModel>, String>((ref, fleetId) {
  // `fleetTrucksProvider` recrée une nouvelle List à chaque émission du
  // stream global `trucksStreamProvider` (déclenché par l'écriture sur
  // N'IMPORTE QUEL camion, de n'importe quelle flotte). Sans ce `.select`,
  // ce provider détruirait/recréerait son listener Firestore sur `shifts`
  // à chaque écriture camion ailleurs dans l'app, avec un risque de perte
  // d'événement (vacation démarrée/terminée qui ne se reflète qu'après un
  // rechargement complet de la page). On ne dérive donc que la clé
  // (identifiants triés joints en String, comparable par valeur) : le
  // provider ne se recalcule que si l'ENSEMBLE des camions de la flotte
  // change réellement.
  final truckIdsKey = ref.watch(fleetTrucksProvider(fleetId).select((async) {
    final ids = (async.valueOrNull ?? const [])
        .map((t) => t.id)
        .toList()
      ..sort();
    return ids.join(',');
  }));

  if (truckIdsKey.isEmpty) return Stream.value([]);

  final truckIds = truckIdsKey.split(',');
  final repository = ref.watch(shiftRepositoryProvider);
  return repository.watchShiftsForTruckIds(truckIds);
});

/// Provider stream pour les demandes carburant liées à un shift
final fuelRequestsByShiftProvider =
    StreamProvider.family<List<FuelRequestModel>, String>((ref, shiftId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('fuel_requests')
      .where('shiftId', isEqualTo: shiftId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
          .toList());
});

/// Provider stream pour les pesées liées à un shift
final weighingsByShiftProvider =
    StreamProvider.family<List<WeighingRecordModel>, String>((ref, shiftId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('weighings')
      .where('shiftId', isEqualTo: shiftId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => WeighingRecordModel.fromMap(doc.data(), doc.id))
          .toList());
});
