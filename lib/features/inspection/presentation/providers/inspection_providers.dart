import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/models/role.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../data/repositories/inspection_repository.dart';
import '../../domain/models/vehicle_inspection_model.dart';

/// Provider pour le repository d'inspection
final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  return InspectionRepository();
});

/// Provider pour récupérer les inspections d'un véhicule
final inspectionsForTruckProvider =
    FutureProvider.family<List<VehicleInspectionModel>, String>(
        (ref, truckId) async {
  final repository = ref.watch(inspectionRepositoryProvider);
  return repository.getInspectionsForTruck(truckId);
});

/// Provider pour écouter les inspections en temps réel d'un véhicule
final inspectionsStreamProvider =
    StreamProvider.family<List<VehicleInspectionModel>, String>(
        (ref, truckId) {
  final repository = ref.watch(inspectionRepositoryProvider);
  return repository.watchInspectionsForTruck(truckId);
});

/// Provider pour écouter toutes les inspections en temps réel
final allInspectionsStreamProvider =
    StreamProvider<List<VehicleInspectionModel>>((ref) {
  final repository = ref.watch(inspectionRepositoryProvider);
  return repository.watchAllInspections();
});

/// Provider pour les inspections faites par un superviseur
final inspectionsByUserProvider =
    FutureProvider.family<List<VehicleInspectionModel>, String>(
        (ref, userId) async {
  final repository = ref.watch(inspectionRepositoryProvider);
  return repository.getInspectionsByUser(userId);
});

/// Provider pour la dernière inspection d'un véhicule
final lastInspectionForTruckProvider =
    FutureProvider.family<VehicleInspectionModel?, String>(
        (ref, truckId) async {
  final repository = ref.watch(inspectionRepositoryProvider);
  return repository.getLastInspectionForTruck(truckId);
});

/// Provider pour les camions visibles par l'utilisateur connecté.
/// - superviseurFlotte : uniquement les camions de sa flotte
/// - direction / superviseurGeneral : tous les camions actifs
final inspectionAvailableTrucksProvider =
    FutureProvider<List<TruckModel>>((ref) async {
  final user = ref.watch(authControllerProvider).value;
  if (user == null) return <TruckModel>[];

  final userRole = UserRole.fromString(user.role);

  // Si superviseur flotte avec un fleetId, ne montrer que les camions de sa flotte
  if (userRole == UserRole.superviseurFlotte && user.fleetId != null) {
    final allTrucks = await ref.watch(activeTrucksProvider.future);
    return allTrucks.where((t) => t.fleetId == user.fleetId).toList();
  }

  // Direction, superviseur général et autres rôles : tous les camions actifs
  return ref.watch(activeTrucksProvider.future);
});

/// Provider pour les inspections filtrées par flotte de l'utilisateur connecté.
/// - superviseurFlotte : uniquement les inspections des camions de sa flotte
/// - direction / superviseurGeneral : toutes les inspections
final filteredInspectionsStreamProvider =
    StreamProvider<List<VehicleInspectionModel>>((ref) {
  final user = ref.watch(authControllerProvider).value;
  final repository = ref.watch(inspectionRepositoryProvider);
  final allInspections = repository.watchAllInspections();

  if (user == null) return allInspections;

  final userRole = UserRole.fromString(user.role);

  // Si superviseur flotte avec un fleetId, filtrer par les camions de sa flotte
  if (userRole == UserRole.superviseurFlotte && user.fleetId != null) {
    final trucksAsync = ref.watch(trucksStreamProvider);
    final fleetTruckIds = trucksAsync.whenData(
      (trucks) => trucks
          .where((t) => t.fleetId == user.fleetId)
          .map((t) => t.id)
          .toSet(),
    );

    return fleetTruckIds.when(
      data: (truckIds) => allInspections.map(
        (inspections) =>
            inspections.where((i) => truckIds.contains(i.truckId)).toList(),
      ),
      loading: () => const Stream.empty(),
      error: (_, __) => allInspections,
    );
  }

  // Direction, superviseur général et autres rôles : toutes les inspections
  return allInspections;
});
