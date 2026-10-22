import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/truck_model.dart';

/// Repository pour la gestion des camions
class TruckRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'trucks';

  // =============== CRUD DE BASE ===============

  /// Créer un nouveau camion
  Future<TruckModel> createTruck(TruckModel truck) async {
    try {
      final docRef = await _firestore.collection(_collection).add(truck.toMap());
      return truck.copyWith(id: docRef.id);
    } catch (e) {
      throw Exception('Erreur lors de la création du camion: $e');
    }
  }

  /// Récupérer tous les camions
  Future<List<TruckModel>> getAllTrucks() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();

      // Véhicules supprimés exclus (T.40)
      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .where((truck) => truck.isActive)
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des camions: $e');
    }
  }

  /// Récupérer les camions actifs
  Future<List<TruckModel>> getActiveTrucks() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      // Tri côté client pour éviter l'index composite
      final trucks = snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .toList();

      trucks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return trucks;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des camions actifs: $e');
    }
  }

  /// Récupérer un camion par ID
  Future<TruckModel?> getTruckById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (!doc.exists) return null;
      return TruckModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du camion: $e');
    }
  }

  /// Mettre à jour un camion complet
  Future<void> updateTruck(TruckModel truck) async {
    try {
      await _firestore.collection(_collection).doc(truck.id).update(
            truck.copyWith(updatedAt: DateTime.now()).toMap(),
          );
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du camion: $e');
    }
  }

  /// Mettre à jour des champs spécifiques
  Future<void> updateTruckFields(
    String truckId,
    Map<String, dynamic> fields,
  ) async {
    try {
      fields['updatedAt'] = Timestamp.now();
      await _firestore.collection(_collection).doc(truckId).update(fields);
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des champs: $e');
    }
  }

  Future<void> signalHorsService(
    String truckId, {
    required String reason,
  }) async {
    await _firestore.collection(_collection).doc(truckId).update({
      'statut': TruckStatus.immobilise.name,
      'horsServiceAt': Timestamp.now(),
      'horsServiceReason': reason,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> clearHorsService(String truckId) async {
    await _firestore.collection(_collection).doc(truckId).update({
      'statut': TruckStatus.enService.name,
      'horsServiceAt': null,
      'horsServiceReason': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Soft delete - Désactiver un camion
  Future<void> deactivateTruck(String truckId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'isActive': false,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la désactivation du camion: $e');
    }
  }

  /// Réactiver un camion
  Future<void> activateTruck(String truckId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'isActive': true,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la réactivation du camion: $e');
    }
  }

  /// Supprimer définitivement un camion (à utiliser avec précaution)
  /// Raison bloquant la suppression d'un véhicule (T.40), null si aucune.
  /// - `active_shift` : vacation en cours sur le camion
  /// - `pending_fuel_request` : demande de carburant en attente
  Future<String?> checkDeletionBlockers(String truckId) async {
    final activeShift = await _firestore
        .collection('shifts')
        .where('truckId', isEqualTo: truckId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    if (activeShift.docs.isNotEmpty) return 'active_shift';

    final pendingFuel = await _firestore
        .collection('fuel_requests')
        .where('truckId', isEqualTo: truckId)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    if (pendingFuel.docs.isNotEmpty) return 'pending_fuel_request';

    return null;
  }

  /// Supprimer un véhicule (T.40) : désactivation logique, retrait de sa
  /// flotte et fin des affectations chauffeur actives (les chauffeurs
  /// redeviennent affectables — T.19.1). L'historique est conservé.
  Future<void> softDeleteTruck(String truckId, {String? deletedBy}) async {
    final assignments = await _firestore
        .collection('driver_assignments')
        .where('truckId', isEqualTo: truckId)
        .where('isActive', isEqualTo: true)
        .get();

    final batch = _firestore.batch()
      ..update(_firestore.collection(_collection).doc(truckId), {
        'isActive': false,
        'isDeleted': true,
        'fleetId': null,
        'deletedAt': Timestamp.now(),
        'deletedBy': deletedBy,
      });
    for (final doc in assignments.docs) {
      batch.update(doc.reference, {'isActive': false});
    }
    await batch.commit();
  }

  /// Suppression définitive (non utilisée : préférer [softDeleteTruck])
  Future<void> deleteTruck(String truckId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).delete();
    } catch (e) {
      throw Exception('Erreur lors de la suppression du camion: $e');
    }
  }

  // =============== RECHERCHE & FILTRAGE ===============

  /// Rechercher des camions par query
  Future<List<TruckModel>> searchTrucks(String query) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final lowerQuery = query.toLowerCase();
      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .where((truck) =>
              truck.immatriculation.toLowerCase().contains(lowerQuery) ||
              truck.marque.toLowerCase().contains(lowerQuery) ||
              truck.modele.toLowerCase().contains(lowerQuery) ||
              truck.numeroInterneFlotte.toLowerCase().contains(lowerQuery) ||
              truck.numeroChassis.toLowerCase().contains(lowerQuery))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la recherche de camions: $e');
    }
  }

  /// Récupérer les camions par type
  Future<List<TruckModel>> getTrucksByType(TruckType type) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('type', isEqualTo: type.name)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des camions par type: $e');
    }
  }

  /// Récupérer les camions par statut
  Future<List<TruckModel>> getTrucksByStatus(TruckStatus status) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('statut', isEqualTo: status.name)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des camions par statut: $e');
    }
  }

  /// Récupérer les camions assignés à un chauffeur
  Future<List<TruckModel>> getTrucksByDriver(String driverId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .where((truck) =>
              truck.chauffeurPrincipalId == driverId ||
              truck.chauffeurSecondaireId == driverId)
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des camions du chauffeur: $e');
    }
  }

  /// Récupérer les camions par site d'affectation
  Future<List<TruckModel>> getTrucksBySite(String site) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('siteAffectation', isEqualTo: site)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des camions par site: $e');
    }
  }

  // =============== STATISTIQUES ===============

  /// Compter tous les camions
  Future<int> getTruckCount() async {
    try {
      // Véhicules supprimés exclus (T.40)
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des camions: $e');
    }
  }

  /// Compter les camions actifs
  Future<int> getActiveTruckCount() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Erreur lors du comptage des camions actifs: $e');
    }
  }

  /// Obtenir les statistiques par statut
  Future<Map<String, int>> getTruckStatsByStatus() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final stats = <String, int>{};
      for (final status in TruckStatus.values) {
        stats[status.name] = 0;
      }

      for (final doc in snapshot.docs) {
        final truck = TruckModel.fromMap(doc.data(), doc.id);
        stats[truck.statut.name] = (stats[truck.statut.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  /// Obtenir les statistiques par type
  Future<Map<String, int>> getTruckStatsByType() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .get();

      final stats = <String, int>{};
      for (final type in TruckType.values) {
        stats[type.name] = 0;
      }

      for (final doc in snapshot.docs) {
        final truck = TruckModel.fromMap(doc.data(), doc.id);
        stats[truck.type.name] = (stats[truck.type.name] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      throw Exception('Erreur lors de la récupération des statistiques: $e');
    }
  }

  // =============== REAL-TIME MONITORING ===============

  /// Écouter tous les camions en temps réel
  /// Tous les camions en service dans l'application.
  /// Les véhicules supprimés (isActive = false — T.40) sont exclus de
  /// toutes les listes, KPI et sélecteurs qui s'appuient sur ce flux.
  Stream<List<TruckModel>> watchAllTrucks() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
            .where((truck) => truck.isActive)
            .toList());
  }

  /// Écouter un camion spécifique en temps réel
  Stream<TruckModel?> watchTruck(String truckId) {
    return _firestore.collection(_collection).doc(truckId).snapshots().map(
          (doc) =>
              doc.exists ? TruckModel.fromMap(doc.data()!, doc.id) : null,
        );
  }

  /// Écouter les camions actifs en temps réel
  Stream<List<TruckModel>> watchActiveTrucks() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // =============== MAINTENANCE ===============

  /// Mettre à jour le kilométrage
  Future<void> updateMileage(String truckId, int newMileage) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'kilometrageActuel': newMileage,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du kilométrage: $e');
    }
  }

  /// Mettre à jour les heures moteur
  Future<void> updateEngineHours(String truckId, int hours) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'heuresMoteur': hours,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour des heures moteur: $e');
    }
  }

  /// Enregistrer une maintenance
  Future<void> recordMaintenance({
    required String truckId,
    required DateTime date,
    required String type,
    DateTime? nextMaintenance,
  }) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'derniereMaintenanceDate': Timestamp.fromDate(date),
        'derniereMaintenanceType': type,
        if (nextMaintenance != null)
          'prochaineMaintenancePrevue': Timestamp.fromDate(nextMaintenance),
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'enregistrement de la maintenance: $e');
    }
  }

  /// Récupérer les camions nécessitant une maintenance
  Future<List<TruckModel>> getTrucksNeedingMaintenance() async {
    try {
      final now = DateTime.now();
      final in30Days = now.add(const Duration(days: 30));

      final snapshot = await _firestore
          .collection(_collection)
          .where('isActive', isEqualTo: true)
          .where('prochaineMaintenancePrevue',
              isLessThanOrEqualTo: Timestamp.fromDate(in30Days))
          .get();

      return snapshot.docs
          .map((doc) => TruckModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw Exception(
          'Erreur lors de la récupération des camions à maintenir: $e');
    }
  }

  // =============== ASSIGNATION ===============

  /// Assigner un chauffeur principal
  Future<void> assignMainDriver(String truckId, String driverId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'chauffeurPrincipalId': driverId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du chauffeur: $e');
    }
  }

  /// Assigner un chauffeur secondaire
  Future<void> assignSecondaryDriver(String truckId, String? driverId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'chauffeurSecondaireId': driverId,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors de l\'assignation du chauffeur secondaire: $e');
    }
  }

  /// Retirer tous les chauffeurs
  Future<void> unassignDrivers(String truckId) async {
    try {
      await _firestore.collection(_collection).doc(truckId).update({
        'chauffeurPrincipalId': null,
        'chauffeurSecondaireId': null,
        'updatedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Erreur lors du retrait des chauffeurs: $e');
    }
  }

  // =============== VALIDATION ===============

  /// Vérifier si une immatriculation existe déjà
  Future<bool> immatriculationExists(String immatriculation) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('immatriculation', isEqualTo: immatriculation)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification de l\'immatriculation: $e');
    }
  }

  /// Vérifier si un numéro de châssis existe déjà
  Future<bool> vinExists(String vin) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('numeroChassis', isEqualTo: vin)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Erreur lors de la vérification du numéro de châssis: $e');
    }
  }

  /// Vérifier si un numéro interne de flotte existe déjà
  Future<bool> fleetNumberExists(String fleetNumber) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('numeroInterneFlotte', isEqualTo: fleetNumber)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception(
          'Erreur lors de la vérification du numéro de flotte: $e');
    }
  }
}
