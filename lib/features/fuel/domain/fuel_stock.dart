import 'models/fuel_request_model.dart';
import 'models/fuel_supply_entry_model.dart';

/// Une demande a physiquement consommé du stock dès qu'elle a été servie,
/// quel que soit son statut ensuite (validée, contestée, rejetée).
bool isServed(FuelRequestModel r) =>
    r.fulfilledLiters != null && r.status != FuelRequestStatus.cancelled;

/// Demande acceptée mais pas encore servie : le litrage est réservé.
bool isReserved(FuelRequestModel r) => r.status == FuelRequestStatus.pending;

/// Résumé du stock carburant.
class FuelStockSummary {
  const FuelStockSummary({
    required this.totalDelivered,
    required this.totalDispensed,
    this.totalReserved = 0,
  });

  factory FuelStockSummary.compute(
    List<FuelSupplyEntryModel> supplies,
    List<FuelRequestModel> requests,
  ) {
    return FuelStockSummary(
      totalDelivered: supplies.fold(0.0, (s, e) => s + e.litersDelivered),
      totalDispensed: requests
          .where(isServed)
          .fold(0.0, (s, r) => s + (r.fulfilledLiters ?? 0)),
      totalReserved: requests
          .where(isReserved)
          .fold(0.0, (s, r) => s + r.requestedLiters),
    );
  }

  /// Total livré par les ravitaillements
  final double totalDelivered;

  /// Total servi aux camions
  final double totalDispensed;

  /// Total des demandes en attente (pas encore servies)
  final double totalReserved;

  /// Stock physiquement présent dans la cuve
  double get available => totalDelivered - totalDispensed;

  /// Litrage encore demandable : stock moins demandes en attente
  double get availableForRequest => available - totalReserved;
}

/// Type de mouvement du relevé carburant
enum FuelMovementType { supply, dispense }

/// Ligne du relevé carburant (façon relevé bancaire)
class FuelStockMovement {
  const FuelStockMovement({
    required this.date,
    required this.type,
    required this.liters,
    required this.balanceAfter,
    required this.label,
    this.reference,
    this.operator,
  });

  final DateTime date;
  final FuelMovementType type;

  /// Litrage signé : + entrée (ravitaillement), − sortie (service)
  final double liters;

  /// Solde du stock après ce mouvement
  final double balanceAfter;

  /// Libellé : fournisseur, ou immatriculation du camion servi
  final String label;

  /// N° de facture ou n° de reçu
  final String? reference;

  /// Personne ayant saisi l'opération
  final String? operator;

  bool get isCredit => liters >= 0;
}

/// Construit le relevé chronologique (plus récent en premier) avec le solde
/// après chaque mouvement.
List<FuelStockMovement> buildFuelLedger(
  List<FuelSupplyEntryModel> supplies,
  List<FuelRequestModel> requests,
) {
  final raw = <({
    DateTime date,
    FuelMovementType type,
    double liters,
    String label,
    String? reference,
    String? operator,
  })>[
    for (final s in supplies)
      (
        date: s.date,
        type: FuelMovementType.supply,
        liters: s.litersDelivered,
        label: s.supplierName ?? '',
        reference: s.invoiceNumber,
        operator: s.createdByName,
      ),
    for (final r in requests.where(isServed))
      (
        date: r.fulfilledAt ?? r.createdAt,
        type: FuelMovementType.dispense,
        liters: -(r.fulfilledLiters ?? 0),
        label: (r.truckFleetNumber?.isNotEmpty ?? false)
            ? '${r.truckImmatriculation} (${r.truckFleetNumber})'
            : r.truckImmatriculation,
        reference: r.receiptNumber,
        operator: r.fulfilledByName,
      ),
  ]..sort((a, b) => a.date.compareTo(b.date));

  var balance = 0.0;
  final movements = <FuelStockMovement>[];
  for (final m in raw) {
    balance += m.liters;
    movements.add(FuelStockMovement(
      date: m.date,
      type: m.type,
      liters: m.liters,
      balanceAfter: balance,
      label: m.label,
      reference: m.reference,
      operator: m.operator,
    ));
  }
  return movements.reversed.toList();
}

/// Litrage demandé ou servi supérieur au stock disponible
class InsufficientFuelStockException implements Exception {
  const InsufficientFuelStockException({
    required this.requested,
    required this.available,
  });

  final double requested;

  /// Litrage disponible au moment du contrôle (jamais négatif)
  final double available;

  @override
  String toString() => 'insufficient_stock';
}
