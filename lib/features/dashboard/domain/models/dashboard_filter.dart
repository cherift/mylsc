import 'package:flutter/material.dart';

/// Modèle de filtre pour les dashboards
/// Permet de filtrer les données par plage de dates, par liste de camions
/// et/ou par client (pesées — T.37)
class DashboardFilter {
  const DashboardFilter({
    this.dateRange,
    this.selectedTruckIds,
    this.selectedClientIds,
  });

  /// Identifiant réservé aux pesées sans client (antérieures à T.34)
  static const noClientId = '__none__';

  /// Plage de dates sélectionnée (null = pas de restriction)
  final DateTimeRange? dateRange;

  /// IDs des camions sélectionnés (null = pas de restriction, empty set = aucun)
  final Set<String>? selectedTruckIds;

  /// IDs des clients sélectionnés (null = pas de restriction).
  /// Peut contenir [noClientId] pour inclure les pesées sans client.
  final Set<String>? selectedClientIds;

  /// Vrai si au moins un filtre est actif
  bool get isActive =>
      dateRange != null ||
      (selectedTruckIds != null && selectedTruckIds!.isNotEmpty) ||
      selectedClientIds != null;

  /// Vérifie si une pesée (par son client) passe le filtre
  bool matchesClient(String? clientId) {
    if (selectedClientIds == null) return true;
    return selectedClientIds!.contains(clientId ?? noClientId);
  }

  /// Vérifie si un camion passe le filtre
  bool matchesTruck(String truckId) {
    if (selectedTruckIds == null) return true;
    return selectedTruckIds!.contains(truckId);
  }

  /// Vérifie si une date passe le filtre
  bool matchesDate(DateTime? dt) {
    if (dateRange == null || dt == null) return true;
    final start = DateTime(
      dateRange!.start.year,
      dateRange!.start.month,
      dateRange!.start.day,
    );
    final end = DateTime(
      dateRange!.end.year,
      dateRange!.end.month,
      dateRange!.end.day,
      23,
      59,
      59,
    );
    return !dt.isBefore(start) && !dt.isAfter(end);
  }

  /// Crée une copie avec des modifications
  DashboardFilter copyWith({
    DateTimeRange? dateRange,
    Set<String>? selectedTruckIds,
    Set<String>? selectedClientIds,
    bool clearDateRange = false,
    bool clearTruckIds = false,
    bool clearClientIds = false,
  }) {
    return DashboardFilter(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      selectedTruckIds:
          clearTruckIds ? null : (selectedTruckIds ?? this.selectedTruckIds),
      selectedClientIds: clearClientIds
          ? null
          : (selectedClientIds ?? this.selectedClientIds),
    );
  }
}
