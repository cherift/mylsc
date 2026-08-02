import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/truck_repository.dart';
import '../../data/services/truck_display_preferences_service.dart';
import '../../domain/models/truck_field.dart';
import '../../domain/models/truck_model.dart';

// =============== REPOSITORY PROVIDER ===============

final truckRepositoryProvider = Provider<TruckRepository>((ref) {
  return TruckRepository();
});

// =============== SERVICES PROVIDERS ===============

final truckDisplayPreferencesServiceProvider =
    Provider<TruckDisplayPreferencesService>((ref) {
  return TruckDisplayPreferencesService();
});

/// Provider pour les champs visibles
final visibleTruckFieldsProvider = FutureProvider<List<TruckField>>((ref) async {
  final service = ref.watch(truckDisplayPreferencesServiceProvider);
  final visibleKeys = await service.loadVisibleFields();

  return TruckFields.allFields
      .where((field) => visibleKeys.contains(field.key))
      .toList();
});

// =============== FUTURE PROVIDERS ===============

/// Provider pour tous les camions
final allTrucksProvider = FutureProvider<List<TruckModel>>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getAllTrucks();
});

/// Provider pour les camions actifs
final activeTrucksProvider = FutureProvider<List<TruckModel>>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getActiveTrucks();
});

/// Provider pour les statistiques par statut
final truckStatsByStatusProvider =
    FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTruckStatsByStatus();
});

/// Provider pour les statistiques par type
final truckStatsByTypeProvider = FutureProvider<Map<String, int>>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTruckStatsByType();
});

/// Provider pour le nombre total de camions
final truckCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTruckCount();
});

/// Provider pour le nombre de camions actifs
final activeTruckCountProvider = FutureProvider<int>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getActiveTruckCount();
});

/// Provider pour les camions nécessitant une maintenance
final trucksNeedingMaintenanceProvider =
    FutureProvider<List<TruckModel>>((ref) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTrucksNeedingMaintenance();
});

// =============== FAMILY PROVIDERS ===============

/// Provider pour un camion spécifique par ID
final truckProvider =
    FutureProvider.family<TruckModel?, String>((ref, truckId) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTruckById(truckId);
});

/// Provider pour les camions par type
final trucksByTypeProvider =
    FutureProvider.family<List<TruckModel>, TruckType>((ref, type) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTrucksByType(type);
});

/// Provider pour les camions par statut
final trucksByStatusProvider =
    FutureProvider.family<List<TruckModel>, TruckStatus>((ref, status) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTrucksByStatus(status);
});

/// Provider pour les camions par chauffeur
final trucksByDriverProvider =
    FutureProvider.family<List<TruckModel>, String>((ref, driverId) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTrucksByDriver(driverId);
});

/// Provider pour les camions par site
final trucksBySiteProvider =
    FutureProvider.family<List<TruckModel>, String>((ref, site) async {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.getTrucksBySite(site);
});

/// Provider pour la recherche de camions
final searchTrucksProvider =
    FutureProvider.family<List<TruckModel>, String>((ref, query) async {
  if (query.isEmpty) {
    return ref.watch(activeTrucksProvider).maybeWhen(
          data: (trucks) => trucks,
          orElse: () => [],
        );
  }
  final repository = ref.watch(truckRepositoryProvider);
  return repository.searchTrucks(query);
});

// =============== STREAM PROVIDERS ===============

/// Provider en temps réel pour tous les camions
final trucksStreamProvider = StreamProvider<List<TruckModel>>((ref) {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.watchAllTrucks();
});

/// Provider en temps réel pour les camions actifs
final activeTrucksStreamProvider = StreamProvider<List<TruckModel>>((ref) {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.watchActiveTrucks();
});

/// Provider en temps réel pour un camion spécifique
final truckStreamProvider =
    StreamProvider.family<TruckModel?, String>((ref, truckId) {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.watchTruck(truckId);
});
