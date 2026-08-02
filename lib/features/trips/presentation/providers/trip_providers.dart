import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/trip_repository.dart';
import '../../domain/models/trip_model.dart';

/// Provider pour le repository des rotations
final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return TripRepository();
});

// ── Streams temps réel ──

/// Stream des rotations en attente de validation
final pendingTripsStreamProvider =
    StreamProvider<List<TripModel>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchPendingValidation();
});

/// Stream de toutes les rotations
final allTripsStreamProvider =
    StreamProvider<List<TripModel>>((ref) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchAllTrips();
});

/// Stream des rotations d'un chauffeur
final driverTripsStreamProvider =
    StreamProvider.family<List<TripModel>, String>((ref, driverId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTripsByDriver(driverId);
});

/// Stream des rotations d'un camion
final truckTripsStreamProvider =
    StreamProvider.family<List<TripModel>, String>((ref, truckId) {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.watchTripsByTruck(truckId);
});

// ── Lecture unique ──

/// Provider pour une rotation par ID
final tripByIdProvider =
    FutureProvider.family<TripModel?, String>((ref, tripId) async {
  final repository = ref.watch(tripRepositoryProvider);
  return repository.getTrip(tripId);
});
