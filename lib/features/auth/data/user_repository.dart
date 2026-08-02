import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

/// Provider pour le repository utilisateur
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

/// Repository pour la gestion des utilisateurs dans Firestore
class UserRepository {
  UserRepository(this._firestore);
  final FirebaseFirestore _firestore;

  /// Référence à la collection users
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Crée un nouvel utilisateur
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.id).set(user.toFirestore());
  }

  /// Récupère un utilisateur par son ID
  Future<UserModel?> getUserById(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Récupère un utilisateur par son email
  Future<UserModel?> getUserByEmail(String email) async {
    final query =
        await _usersCollection.where('email', isEqualTo: email).limit(1).get();

    if (query.docs.isEmpty) return null;
    return UserModel.fromFirestore(query.docs.first);
  }

  /// Met à jour un utilisateur
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.id).update(user.toFirestore());
  }

  /// Met à jour des champs spécifiques
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    await _usersCollection.doc(userId).update(fields);
  }

  /// Met à jour la date de dernière connexion
  Future<void> updateLastLogin(String userId) async {
    await _usersCollection.doc(userId).update({
      'lastLoginAt': FieldValue.serverTimestamp(),
    });
  }

  /// Supprime un utilisateur
  Future<void> deleteUser(String userId) async {
    await _usersCollection.doc(userId).delete();
  }

  /// Désactive un utilisateur
  Future<void> deactivateUser(String userId) async {
    await _usersCollection.doc(userId).update({'isActive': false});
  }

  /// Active un utilisateur
  Future<void> activateUser(String userId) async {
    await _usersCollection.doc(userId).update({'isActive': true});
  }

  /// Récupère tous les utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    final query =
        await _usersCollection.orderBy('createdAt', descending: true).get();
    return query.docs.map(UserModel.fromFirestore).toList();
  }

  /// Récupère les utilisateurs actifs
  Future<List<UserModel>> getActiveUsers() async {
    final query = await _usersCollection
        .where('isActive', isEqualTo: true)
        .orderBy('displayName')
        .get();
    return query.docs.map(UserModel.fromFirestore).toList();
  }

  /// Récupère les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(String role) async {
    final query = await _usersCollection
        .where('role', isEqualTo: role)
        .where('isActive', isEqualTo: true)
        .get();
    return query.docs.map(UserModel.fromFirestore).toList();
  }

  /// Stream d'un utilisateur (temps réel)
  Stream<UserModel?> watchUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Stream de tous les utilisateurs (temps réel)
  Stream<List<UserModel>> watchAllUsers() {
    return _usersCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((query) => query.docs.map(UserModel.fromFirestore).toList());
  }

  /// Vérifie si un email existe déjà
  Future<bool> emailExists(String email) async {
    final query =
        await _usersCollection.where('email', isEqualTo: email).limit(1).get();
    return query.docs.isNotEmpty;
  }

  /// Recherche d'utilisateurs
  Future<List<UserModel>> searchUsers(String query) async {
    // Firestore ne supporte pas la recherche full-text nativement
    // Cette implémentation est basique et fonctionne pour de petites collections
    final allUsers = await getAllUsers();
    final lowerQuery = query.toLowerCase();

    return allUsers.where((user) {
      final name = user.displayName?.toLowerCase() ?? '';
      final email = user.email.toLowerCase();
      return name.contains(lowerQuery) || email.contains(lowerQuery);
    }).toList();
  }

  /// Compte le nombre d'utilisateurs
  Future<int> getUserCount() async {
    final query = await _usersCollection.count().get();
    return query.count ?? 0;
  }

  /// Compte les utilisateurs actifs
  Future<int> getActiveUserCount() async {
    final query =
        await _usersCollection.where('isActive', isEqualTo: true).count().get();
    return query.count ?? 0;
  }
}
