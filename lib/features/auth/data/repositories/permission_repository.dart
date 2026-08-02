import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/permission.dart';
import '../../domain/models/permission_history.dart';

/// Repository pour gérer les permissions et leur historique
class PermissionRepository {
  PermissionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Mettre à jour les permissions d'un utilisateur
  Future<void> updateUserPermissions({
    required String userId,
    required List<Permission> permissions,
    required String modifiedBy,
    required String modifiedByName,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    // Mise à jour du document utilisateur
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'permissions': permissions.map((p) => p.name).toList(),
      'lastPermissionUpdate': FieldValue.serverTimestamp(),
    });

    // Création de l'entrée d'historique
    final historyRef = userRef.collection('permissionHistory').doc();
    final historyEntry = PermissionHistoryEntry(
      id: historyRef.id,
      timestamp: DateTime.now(),
      modifiedBy: modifiedBy,
      modifiedByName: modifiedByName,
      changeType: PermissionChangeType.permissionsModified,
      addedPermissions: permissions.map((p) => p.name).toList(),
      reason: reason,
    );

    batch.set(historyRef, historyEntry.toMap());

    await batch.commit();
  }

  /// Changer le rôle d'un utilisateur
  Future<void> changeUserRole({
    required String userId,
    required String newRole,
    required String newMatricule,
    required String previousRole,
    required String modifiedBy,
    required String modifiedByName,
    String? reason,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final userRef = _firestore.collection('users').doc(userId);

      // Mettre à jour le rôle et le matricule
      transaction.update(userRef, {
        'role': newRole,
        'matricule': newMatricule,
        'lastPermissionUpdate': FieldValue.serverTimestamp(),
      });

      // Créer l'entrée d'historique
      final historyRef = userRef.collection('permissionHistory').doc();
      final historyEntry = PermissionHistoryEntry(
        id: historyRef.id,
        timestamp: DateTime.now(),
        modifiedBy: modifiedBy,
        modifiedByName: modifiedByName,
        changeType: PermissionChangeType.roleChanged,
        previousRole: previousRole,
        newRole: newRole,
        reason: reason,
      );

      transaction.set(historyRef, historyEntry.toMap());
    });
  }

  /// Ajouter des permissions à un utilisateur
  Future<void> addPermissions({
    required String userId,
    required List<Permission> permissions,
    required String modifiedBy,
    required String modifiedByName,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    // Récupérer les permissions actuelles
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentPermissions =
        (userDoc.data()?['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    // Ajouter les nouvelles permissions
    final newPermissions = {
      ...currentPermissions,
      ...permissions.map((p) => p.name)
    }.toList();

    // Mise à jour du document utilisateur
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'permissions': newPermissions,
      'lastPermissionUpdate': FieldValue.serverTimestamp(),
    });

    // Création de l'entrée d'historique
    final historyRef = userRef.collection('permissionHistory').doc();
    final historyEntry = PermissionHistoryEntry(
      id: historyRef.id,
      timestamp: DateTime.now(),
      modifiedBy: modifiedBy,
      modifiedByName: modifiedByName,
      changeType: PermissionChangeType.permissionsAdded,
      addedPermissions: permissions.map((p) => p.name).toList(),
      reason: reason,
    );

    batch.set(historyRef, historyEntry.toMap());

    await batch.commit();
  }

  /// Retirer des permissions d'un utilisateur
  Future<void> removePermissions({
    required String userId,
    required List<Permission> permissions,
    required String modifiedBy,
    required String modifiedByName,
    String? reason,
  }) async {
    final batch = _firestore.batch();

    // Récupérer les permissions actuelles
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final currentPermissions =
        (userDoc.data()?['permissions'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            [];

    // Retirer les permissions
    final permissionsToRemove = permissions.map((p) => p.name).toSet();
    final newPermissions = currentPermissions
        .where((p) => !permissionsToRemove.contains(p))
        .toList();

    // Mise à jour du document utilisateur
    final userRef = _firestore.collection('users').doc(userId);
    batch.update(userRef, {
      'permissions': newPermissions,
      'lastPermissionUpdate': FieldValue.serverTimestamp(),
    });

    // Création de l'entrée d'historique
    final historyRef = userRef.collection('permissionHistory').doc();
    final historyEntry = PermissionHistoryEntry(
      id: historyRef.id,
      timestamp: DateTime.now(),
      modifiedBy: modifiedBy,
      modifiedByName: modifiedByName,
      changeType: PermissionChangeType.permissionsRemoved,
      removedPermissions: permissions.map((p) => p.name).toList(),
      reason: reason,
    );

    batch.set(historyRef, historyEntry.toMap());

    await batch.commit();
  }

  /// Récupérer l'historique des permissions d'un utilisateur
  Future<List<PermissionHistoryEntry>> getPermissionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('permissionHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => PermissionHistoryEntry.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Écouter les changements d'historique en temps réel
  Stream<List<PermissionHistoryEntry>> watchPermissionHistory(
    String userId, {
    int limit = 50,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('permissionHistory')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PermissionHistoryEntry.fromMap(doc.data(), doc.id))
            .toList());
  }
}
