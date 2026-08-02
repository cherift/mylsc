import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/breakdown_repository.dart';
import '../../domain/models/breakdown_report_model.dart';

/// Provider pour le repository des pannes
final breakdownRepositoryProvider = Provider<BreakdownRepository>((ref) {
  return BreakdownRepository();
});

// ── Lecture par statut ──

/// Provider pour les pannes en attente
final pendingBreakdownsProvider =
    FutureProvider<List<BreakdownReportModel>>((ref) async {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.getBreakdownsByStatus(BreakdownStatus.pending);
});

/// Provider pour les pannes d'un camion
final truckBreakdownsProvider =
    FutureProvider.family<List<BreakdownReportModel>, String>(
        (ref, truckId) async {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.getBreakdownsByTruck(truckId);
});

// ── Streams temps réel ──

/// Stream des pannes en attente
final pendingBreakdownsStreamProvider =
    StreamProvider<List<BreakdownReportModel>>((ref) {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.watchPendingBreakdowns();
});

/// Stream des pannes actives (non clôturées)
final activeBreakdownsStreamProvider =
    StreamProvider<List<BreakdownReportModel>>((ref) {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.watchActiveBreakdowns();
});

/// Stream de toutes les pannes
final allBreakdownsStreamProvider =
    StreamProvider<List<BreakdownReportModel>>((ref) {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.watchAllBreakdowns();
});

/// Stream des pannes d'un camion
final truckBreakdownsStreamProvider =
    StreamProvider.family<List<BreakdownReportModel>, String>(
        (ref, truckId) {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.watchBreakdownsByTruck(truckId);
});

/// Stream des pannes assignées à un technicien
final technicianBreakdownsStreamProvider =
    StreamProvider.family<List<BreakdownReportModel>, String>(
        (ref, technicianId) {
  final repository = ref.watch(breakdownRepositoryProvider);
  return repository.watchBreakdownsByTechnician(technicianId);
});
