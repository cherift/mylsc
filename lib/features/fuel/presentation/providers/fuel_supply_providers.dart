import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fuel_supply_repository.dart';
import '../../domain/fuel_stock.dart';
import '../../domain/models/fuel_supply_entry_model.dart';
import 'fuel_request_providers.dart';

export '../../domain/fuel_stock.dart';

final fuelSupplyRepositoryProvider = Provider<FuelSupplyRepository>(
  (ref) => FuelSupplyRepository(),
);

final fuelSupplyEntriesProvider =
    StreamProvider<List<FuelSupplyEntryModel>>((ref) {
  return ref.watch(fuelSupplyRepositoryProvider).watchAll();
});

/// Stock carburant en temps réel : livré − servi, et litrage encore
/// demandable (stock − demandes en attente).
final fuelStockProvider = Provider<AsyncValue<FuelStockSummary>>((ref) {
  final supplies = ref.watch(fuelSupplyEntriesProvider);
  final requests = ref.watch(allRequestsStreamProvider);

  return supplies.when(
    data: (supplyList) => requests.when(
      data: (requestList) =>
          AsyncValue.data(FuelStockSummary.compute(supplyList, requestList)),
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Relevé carburant (entrées + / sorties −) avec solde courant
final fuelLedgerProvider =
    Provider<AsyncValue<List<FuelStockMovement>>>((ref) {
  final supplies = ref.watch(fuelSupplyEntriesProvider);
  final requests = ref.watch(allRequestsStreamProvider);

  return supplies.when(
    data: (supplyList) => requests.when(
      data: (requestList) =>
          AsyncValue.data(buildFuelLedger(supplyList, requestList)),
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});
