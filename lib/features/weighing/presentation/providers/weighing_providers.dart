import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shifts/presentation/providers/shift_providers.dart';
import '../../../trucks/presentation/providers/truck_providers.dart';
import '../../../trucks/domain/models/truck_model.dart';
import '../../data/repositories/weighing_repository.dart';
import '../../domain/models/weighing_record_model.dart';

/// Provider pour le repository des pesées
final weighingRepositoryProvider = Provider<WeighingRepository>((ref) {
  return WeighingRepository();
});

// ── Streams temps réel ──

/// Stream des pesées à la mine
final mineWeighingsStreamProvider =
    StreamProvider<List<WeighingRecordModel>>((ref) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordsByLocation(WeighingLocation.mine);
});

/// Stream des pesées au port
final portWeighingsStreamProvider =
    StreamProvider<List<WeighingRecordModel>>((ref) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordsByLocation(WeighingLocation.port);
});

/// Stream de toutes les pesées
final allWeighingsStreamProvider =
    StreamProvider<List<WeighingRecordModel>>((ref) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchAllRecords();
});

/// Stream des pesées d'un utilisateur
final userWeighingsStreamProvider =
    StreamProvider.family<List<WeighingRecordModel>, String>(
        (ref, userId) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordsByUser(userId);
});

/// Stream des pesées d'un chauffeur
final driverWeighingsStreamProvider =
    StreamProvider.family<List<WeighingRecordModel>, String>(
        (ref, driverId) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordsByDriver(driverId);
});

/// Stream des pesées en attente d'un utilisateur
final pendingWeighingsByUserProvider =
    StreamProvider.family<List<WeighingRecordModel>, String>(
        (ref, userId) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchPendingByUser(userId);
});

// ── Lecture par camion ──

/// Provider pour les pesées d'un camion
final truckWeighingsProvider =
    FutureProvider.family<List<WeighingRecordModel>, String>(
        (ref, truckId) async {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.getRecordsByTruck(truckId);
});

// ── Stockage : pesées en attente de chargement/déchargement ──

/// Stream des pesées mine avec status=recorded (en attente de chargement)
final mineRecordedWeighingsStreamProvider =
    StreamProvider<List<WeighingRecordModel>>((ref) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordedByLocation(WeighingLocation.mine);
});

/// Stream des pesées port avec status=recorded (en attente de déchargement)
final portRecordedWeighingsStreamProvider =
    StreamProvider<List<WeighingRecordModel>>((ref) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchRecordedByLocation(WeighingLocation.port);
});

// ── T.27.2 — Événements Stockage ──

/// Stream des événements stockage non lus pour une flotte
final unreadStorageEventsProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>(
        (ref, fleetId) {
  final repository = ref.watch(weighingRepositoryProvider);
  return repository.watchUnreadStorageEvents(fleetId);
});

// ── T.27.3 — Camions en vacation active ──

/// Stream des camions actifs ayant une vacation en cours
final trucksInActiveShiftProvider = StreamProvider<List<TruckModel>>((ref) {
  final shiftsAsync = ref.watch(activeShiftsStreamProvider);
  final trucksAsync = ref.watch(activeTrucksStreamProvider);

  final shifts = shiftsAsync.valueOrNull ?? [];
  final trucks = trucksAsync.valueOrNull ?? [];
  final activeTruckIds = shifts.map((s) => s.truckId).toSet();

  return Stream.value(
    trucks.where((t) => activeTruckIds.contains(t.id)).toList(),
  );
});

/// Stream des camions actifs (temps réel)
final activeTrucksStreamProvider = StreamProvider<List<TruckModel>>((ref) {
  final repository = ref.watch(truckRepositoryProvider);
  return repository.watchActiveTrucks();
});
