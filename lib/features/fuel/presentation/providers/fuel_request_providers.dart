import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fuel_request_repository.dart';
import '../../domain/models/fuel_request_model.dart';

/// Provider pour le repository des demandes de carburant
final fuelRequestRepositoryProvider =
    Provider<FuelRequestRepository>((ref) {
  return FuelRequestRepository();
});

// ── Lecture par statut ──

/// Provider pour les demandes en attente
final pendingFuelRequestsProvider =
    FutureProvider<List<FuelRequestModel>>((ref) async {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.getRequestsByStatus(FuelRequestStatus.pending);
});

/// Provider pour les demandes d'un utilisateur
final userFuelRequestsProvider =
    FutureProvider.family<List<FuelRequestModel>, String>(
        (ref, userId) async {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.getRequestsByUser(userId);
});

// ── Streams temps réel ──

/// Stream des demandes en attente (chef ravitaillement)
final pendingRequestsStreamProvider =
    StreamProvider<List<FuelRequestModel>>((ref) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchPendingRequests();
});

/// Stream des demandes servies par un pompiste (onglet activités)
final fulfilledByUserRequestsStreamProvider =
    StreamProvider.family<List<FuelRequestModel>, String>(
        (ref, userId) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchRequestsFulfilledBy(userId);
});

/// Stream de toutes les demandes (chef ravitaillement)
final allRequestsStreamProvider =
    StreamProvider<List<FuelRequestModel>>((ref) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchAllRequests();
});

/// Stream des demandes contestées (responsable opérations)
final disputedRequestsStreamProvider =
    StreamProvider<List<FuelRequestModel>>((ref) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchDisputedRequests();
});

/// Stream des demandes d'un utilisateur
final userRequestsStreamProvider =
    StreamProvider.family<List<FuelRequestModel>, String>(
        (ref, userId) {
  final repository = ref.watch(fuelRequestRepositoryProvider);
  return repository.watchRequestsByUser(userId);
});
