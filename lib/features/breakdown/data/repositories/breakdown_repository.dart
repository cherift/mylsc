import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/breakdown_report_model.dart';

/// Repository pour la gestion des signalements de pannes
class BreakdownRepository {
  BreakdownRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _breakdownCollection =>
      _firestore.collection('breakdowns');

  // ── Création ──

  /// Signaler une panne
  Future<BreakdownReportModel> createBreakdown({
    required String truckId,
    required String truckImmatriculation,
    required String reportedBy,
    required String reportedByName,
    required String description,
    required BreakdownSeverity severity,
    String? truckFleetNumber,
    String? location,
  }) async {
    final report = BreakdownReportModel(
      id: '',
      truckId: truckId,
      truckImmatriculation: truckImmatriculation,
      truckFleetNumber: truckFleetNumber,
      reportedBy: reportedBy,
      reportedByName: reportedByName,
      description: description,
      severity: severity,
      location: location,
      createdAt: DateTime.now(),
    );

    final docRef = await _breakdownCollection.add(report.toMap());
    return report.copyWith(id: docRef.id);
  }

  // ── Assignation ──

  /// Assigner un technicien
  Future<void> assignTechnician({
    required String breakdownId,
    required String assignedTo,
    required String assignedToName,
  }) async {
    await _breakdownCollection.doc(breakdownId).update({
      'status': BreakdownStatus.inDiagnostic.name,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedAt': Timestamp.fromDate(DateTime.now()),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Diagnostic ──

  /// Enregistrer le diagnostic
  Future<void> saveDiagnostic({
    required String breakdownId,
    required String diagnosticResults,
    List<String>? partsNeeded,
    double? estimatedRepairTime,
    double? estimatedCost,
  }) async {
    await _breakdownCollection.doc(breakdownId).update({
      'status': BreakdownStatus.inRepair.name,
      'diagnosticResults': diagnosticResults,
      'partsNeeded': partsNeeded,
      'estimatedRepairTime': estimatedRepairTime,
      'estimatedCost': estimatedCost,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Résolution ──

  /// Marquer comme résolue
  Future<void> resolveBreakdown({
    required String breakdownId,
    required String resolvedBy,
    required String resolvedByName,
    double? actualRepairTime,
    double? actualCost,
  }) async {
    await _breakdownCollection.doc(breakdownId).update({
      'status': BreakdownStatus.resolved.name,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
      'resolvedAt': Timestamp.fromDate(DateTime.now()),
      'actualRepairTime': actualRepairTime,
      'actualCost': actualCost,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  /// Clôturer une panne
  Future<void> closeBreakdown(String breakdownId) async {
    await _breakdownCollection.doc(breakdownId).update({
      'status': BreakdownStatus.closed.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  // ── Lecture ──

  /// Récupérer une panne par ID
  Future<BreakdownReportModel?> getBreakdown(String breakdownId) async {
    final doc = await _breakdownCollection.doc(breakdownId).get();
    if (!doc.exists) return null;
    return BreakdownReportModel.fromMap(doc.data()!, doc.id);
  }

  /// Récupérer les pannes par statut
  Future<List<BreakdownReportModel>> getBreakdownsByStatus(
      BreakdownStatus status) async {
    final snapshot = await _breakdownCollection
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  /// Récupérer les pannes d'un camion
  Future<List<BreakdownReportModel>> getBreakdownsByTruck(
      String truckId) async {
    final snapshot = await _breakdownCollection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ── Streams temps réel ──

  /// Écouter les pannes en attente
  Stream<List<BreakdownReportModel>> watchPendingBreakdowns() {
    return _breakdownCollection
        .where('status', isEqualTo: BreakdownStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pannes actives (non clôturées)
  Stream<List<BreakdownReportModel>> watchActiveBreakdowns() {
    return _breakdownCollection
        .where('status', whereIn: [
          BreakdownStatus.pending.name,
          BreakdownStatus.inDiagnostic.name,
          BreakdownStatus.inRepair.name,
        ])
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter toutes les pannes
  Stream<List<BreakdownReportModel>> watchAllBreakdowns() {
    return _breakdownCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pannes d'un camion
  Stream<List<BreakdownReportModel>> watchBreakdownsByTruck(String truckId) {
    return _breakdownCollection
        .where('truckId', isEqualTo: truckId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter les pannes assignées à un technicien
  Stream<List<BreakdownReportModel>> watchBreakdownsByTechnician(
      String technicianId) {
    return _breakdownCollection
        .where('assignedTo', isEqualTo: technicianId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => BreakdownReportModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
