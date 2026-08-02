import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../fuel/domain/models/fuel_request_model.dart';
import '../../../fuel/presentation/providers/fuel_request_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../auth/domain/models/user_model.dart';
import '../../../users/presentation/providers/user_management_providers.dart';
import '../../data/repositories/fleet_repository.dart';
import '../../domain/models/fleet_model.dart';

// =============== REPOSITORY PROVIDER ===============

final fleetRepositoryProvider = Provider<FleetRepository>((ref) {
  return FleetRepository();
});

// =============== STREAM PROVIDERS ===============

/// Stream de toutes les flottes actives
final allFleetsProvider = StreamProvider<List<FleetModel>>((ref) {
  final repository = ref.watch(fleetRepositoryProvider);
  return repository.watchAllFleets();
});

/// Stream des flottes d'un superviseur
final fleetsBySupervisorProvider =
    StreamProvider.family<List<FleetModel>, String>(
        (ref, supervisorId) {
  final repository = ref.watch(fleetRepositoryProvider);
  return repository.watchFleetsBySupervisor(supervisorId);
});

// =============== FLEET DETAIL PROVIDERS ===============

/// Camions d'une flotte (filtrés depuis le stream global)
final fleetTrucksProvider =
    Provider.family<AsyncValue<List<TruckModel>>, String>((ref, fleetId) {
  final trucksAsync = ref.watch(trucksStreamProvider);
  return trucksAsync.whenData(
    (trucks) => trucks.where((t) => t.fleetId == fleetId).toList(),
  );
});

/// Chauffeurs d'une flotte (filtrés depuis le stream global)
final fleetDriversProvider =
    Provider.family<AsyncValue<List<UserModel>>, String>((ref, fleetId) {
  final usersAsync = ref.watch(usersStreamProvider);
  return usersAsync.whenData(
    (users) => users.where((u) => u.fleetId == fleetId).toList(),
  );
});

/// Demandes carburant d'une flotte
final fleetFuelRequestsProvider =
    StreamProvider.family<List<FuelRequestModel>, String>(
        (ref, fleetId) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchRequestsByFleet(fleetId);
});
