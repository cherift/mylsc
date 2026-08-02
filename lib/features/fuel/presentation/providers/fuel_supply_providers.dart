import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/fuel_supply_repository.dart';
import '../../domain/models/fuel_request_model.dart';
import '../../domain/models/fuel_supply_entry_model.dart';
import 'fuel_request_providers.dart';

final fuelSupplyRepositoryProvider = Provider<FuelSupplyRepository>(
  (ref) => FuelSupplyRepository(),
);

final fuelSupplyEntriesProvider =
    StreamProvider<List<FuelSupplyEntryModel>>((ref) {
  return ref.watch(fuelSupplyRepositoryProvider).watchAll();
});

/// Résumé du stock carburant en temps réel.
class FuelStockSummary {
  const FuelStockSummary({
    required this.totalDelivered,
    required this.totalDispensed,
  });

  final double totalDelivered;
  final double totalDispensed;

  double get available => totalDelivered - totalDispensed;
}

/// Stock carburant disponible = total livré − total servi (fulfilled + validated).
final fuelStockProvider = Provider<AsyncValue<FuelStockSummary>>((ref) {
  final supplies = ref.watch(fuelSupplyEntriesProvider);
  final requests = ref.watch(allRequestsStreamProvider);

  return supplies.when(
    data: (supplyList) => requests.when(
      data: (requestList) {
        final totalDelivered =
            supplyList.fold(0.0, (s, e) => s + e.litersDelivered);
        final totalDispensed = requestList
            .where((r) =>
                r.status == FuelRequestStatus.fulfilled ||
                r.status == FuelRequestStatus.validated)
            .fold(0.0, (s, r) => s + (r.fulfilledLiters ?? 0));
        return AsyncValue.data(FuelStockSummary(
          totalDelivered: totalDelivered,
          totalDispensed: totalDispensed,
        ));
      },
      loading: () => const AsyncValue.loading(),
      error: AsyncValue.error,
    ),
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});
