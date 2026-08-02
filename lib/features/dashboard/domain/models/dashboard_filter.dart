import 'package:flutter/material.dart';

/// Modèle de filtre pour les dashboards
/// Permet de filtrer les données par plage de dates et/ou par liste de camions
class DashboardFilter {
  const DashboardFilter({
    this.dateRange,
    this.selectedTruckIds,
  });

  /// Plage de dates sélectionnée (null = pas de restriction)
  final DateTimeRange? dateRange;

  /// IDs des camions sélectionnés (null = pas de restriction, empty set = aucun)
  final Set<String>? selectedTruckIds;

  /// Vrai si au moins un filtre est actif
  bool get isActive =>
      dateRange != null ||
      (selectedTruckIds != null && selectedTruckIds!.isNotEmpty);

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
    bool clearDateRange = false,
    bool clearTruckIds = false,
  }) {
    return DashboardFilter(
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      selectedTruckIds:
          clearTruckIds ? null : (selectedTruckIds ?? this.selectedTruckIds),
    );
  }
}
