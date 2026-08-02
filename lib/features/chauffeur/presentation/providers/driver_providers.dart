import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../shifts/domain/models/driver_assignment_model.dart';
import '../../../shifts/domain/models/shift_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../../../weighing/domain/models/weighing_record_model.dart';
import '../../../weighing/presentation/providers/weighing_providers.dart';

/// Provider : tous les utilisateurs avec le rôle chauffeur
final allDriversProvider = Provider<AsyncValue<List<UserModel>>>((ref) {
  final usersAsync = ref.watch(usersStreamProvider);
  return usersAsync.whenData(
    (users) => users
        .where((u) => u.role?.toLowerCase() == 'chauffeur')
        .toList(),
  );
});

/// Stats tonnage d'un chauffeur (mine / port)
final driverTonnageStatsProvider = Provider.family<
    AsyncValue<({double mineTonnage, double portTonnage, int mineCount, int portCount})>,
    String>((ref, driverId) {
  final weighingsAsync = ref.watch(driverWeighingsStreamProvider(driverId));
  return weighingsAsync.whenData((weighings) {
    final mine = weighings.where((w) => w.location == WeighingLocation.mine);
    final port = weighings.where((w) => w.location == WeighingLocation.port);
    return (
      mineTonnage: mine.fold(0.0, (acc, w) => acc + w.weight),
      portTonnage: port.fold(0.0, (acc, w) => acc + w.weight),
      mineCount: mine.length,
      portCount: port.length,
    );
  });
});

/// Stream de l'affectation active d'un chauffeur (temps réel)
final activeAssignmentStreamForDriverProvider =
    StreamProvider.family<DriverAssignmentModel?, String>((ref, driverId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('driver_assignments')
      .where('driverId', isEqualTo: driverId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : DriverAssignmentModel.fromMap(snap.docs.first.data(), snap.docs.first.id));
});

/// Stream de la vacation active d'un chauffeur (temps réel)
final activeShiftStreamForDriverProvider =
    StreamProvider.family<ShiftModel?, String>((ref, driverId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('shifts')
      .where('driverId', isEqualTo: driverId)
      .where('isActive', isEqualTo: true)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty
          ? null
          : ShiftModel.fromMap(snap.docs.first.data(), snap.docs.first.id));
});

/// Stream des demandes de carburant d'un chauffeur (par driverId)
final driverFuelRequestsStreamProvider =
    StreamProvider.family<List<FuelRequestModel>, String>((ref, driverId) {
  final firestore = FirebaseFirestore.instance;
  return firestore
      .collection('fuel_requests')
      .where('driverId', isEqualTo: driverId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs
          .map((doc) => FuelRequestModel.fromMap(doc.data(), doc.id))
          .toList());
});
