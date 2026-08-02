import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fuel_repository.dart';
import '../../domain/models/fuel_entry_model.dart';
import '../../../trucks/domain/models/truck_model.dart';

/// Provider pour le repository de carburant
final fuelRepositoryProvider = Provider<FuelRepository>((ref) {
  return FuelRepository();
});

/// Provider pour récupérer les entrées de carburant d'un véhicule
final fuelEntriesForTruckProvider =
    FutureProvider.family<List<FuelEntryModel>, String>((ref, truckId) async {
  final repository = ref.watch(fuelRepositoryProvider);
  return repository.getFuelEntriesForTruck(truckId);
});

/// Provider pour écouter les entrées de carburant en temps réel
final fuelEntriesStreamProvider =
    StreamProvider.family<List<FuelEntryModel>, String>((ref, truckId) {
  final repository = ref.watch(fuelRepositoryProvider);
  return repository.watchFuelEntriesForTruck(truckId);
});

/// Provider pour récupérer les entrées récentes d'un pompiste
final recentFuelEntriesProvider =
    FutureProvider.family<List<FuelEntryModel>, String>((ref, userId) async {
  final repository = ref.watch(fuelRepositoryProvider);
  return repository.getRecentFuelEntries(addedBy: userId);
});

/// Provider pour les statistiques de carburant d'un véhicule
final fuelStatsForTruckProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, truckId) async {
  final repository = ref.watch(fuelRepositoryProvider);
  return repository.getFuelStatsForTruck(truckId);
});

/// Provider pour rechercher un véhicule
final findTruckProvider = FutureProvider.family<TruckModel?, ({String immatriculation, String fleetNumber})>(
  (ref, params) async {
    final repository = ref.watch(fuelRepositoryProvider);
    return repository.findTruckByImmatriculationAndFleetNumber(
      immatriculation: params.immatriculation,
      fleetNumber: params.fleetNumber,
    );
  },
);
