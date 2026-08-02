import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/data/services/matricule_service.dart';
import '../../../auth/domain/models/user_model.dart';

/// Repository pour la gestion des utilisateurs (CRUD complet)
class UserManagementRepository {
  UserManagementRepository({
    FirebaseFirestore? firestore,
    MatriculeService? matriculeService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _matriculeService = matriculeService ?? MatriculeService();

  final FirebaseFirestore _firestore;
  final MatriculeService _matriculeService;

  /// Créer un nouvel utilisateur
  /// Au moins un des deux champs email/phoneNumber doit être fourni.
  /// Si pas d'email, un email système est généré pour Firebase Auth.
  Future<UserModel> createUser({
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    String? email,
    String? phoneNumber,
    String? department,
    String? address,
    String? driverLicenseNumber,
    DateTime? dateOfBirth,
  }) async {
    try {
      final trimmedEmail = email?.trim();
      final trimmedPhone = phoneNumber?.trim();
      final hasEmail = trimmedEmail != null && trimmedEmail.isNotEmpty;
      final hasPhone = trimmedPhone != null && trimmedPhone.isNotEmpty;

      // Validation : au moins un identifiant requis
      if (!hasEmail && !hasPhone) {
        throw Exception('Au moins un email ou un numéro de téléphone est requis');
      }

      // Vérifier l'unicité
      if (hasEmail) {
        final emailTaken = await emailExists(trimmedEmail);
        if (emailTaken) throw Exception('Cet email est déjà utilisé');
      }
      if (hasPhone) {
        final phoneTaken = await phoneExists(trimmedPhone);
        if (phoneTaken) throw Exception('Ce numéro de téléphone est déjà utilisé');
      }

      // Normaliser le téléphone
      String? normalizedPhone;
      if (hasPhone) {
        normalizedPhone = Validators.normalizePhone(trimmedPhone);
      }

      // Générer un email système si pas d'email fourni
      final effectiveEmail = hasEmail
          ? trimmedEmail
          : '${normalizedPhone!.replaceAll('+', '')}@fleet.local';

      // Générer le matricule automatiquement
      final matricule = await _matriculeService.generateMatricule(role);

      // Créer l'utilisateur dans Firebase Auth via une instance secondaire :
      // createUserWithEmailAndPassword connecte automatiquement le client
      // sous le nouveau compte. Passer par une app Firebase jetable évite de
      // remplacer la session de l'administrateur qui effectue l'opération
      // (et permet aux règles Firestore de reconnaître l'admin à l'écriture).
      final secondaryApp = await Firebase.initializeApp(
        name: 'userCreation_${DateTime.now().microsecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);

      late final String newUserId;
      try {
        final userCredential = await secondaryAuth.createUserWithEmailAndPassword(
          email: effectiveEmail,
          password: password,
        );

        if (userCredential.user == null) {
          throw Exception('Échec de la création de l\'utilisateur');
        }
        newUserId = userCredential.user!.uid;

        // Envoyer l'email de vérification (sauf pour les emails système)
        if (!effectiveEmail.endsWith('@fleet.local')) {
          await userCredential.user!.sendEmailVerification();
        }
      } finally {
        await secondaryAuth.signOut();
        await secondaryApp.delete();
      }

      // Créer le profil utilisateur
      final user = UserModel(
        id: newUserId,
        email: effectiveEmail,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: hasPhone ? trimmedPhone : null,
        role: role,
        department: department,
        matricule: matricule,
        address: address,
        driverLicenseNumber: driverLicenseNumber,
        dateOfBirth: dateOfBirth,
        createdAt: DateTime.now(),
      );

      // Sauvegarder dans Firestore avec normalizedPhone
      await _firestore.collection('users').doc(user.id).set({
        ...user.toMap(),
        if (normalizedPhone != null) 'normalizedPhone': normalizedPhone,
      });

      // Table de correspondance minimale pour la connexion par téléphone
      // (ne contient que l'email, jamais le profil complet).
      if (normalizedPhone != null) {
        await _firestore.collection('phone_lookup').doc(normalizedPhone).set({
          'email': effectiveEmail,
        });
      }

      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Créer un chauffeur sans compte Firebase Auth
  Future<UserModel> createDriver({
    required String firstName,
    required String lastName,
    String? phoneNumber,
    String? address,
    String? driverLicenseNumber,
    String? managerId,
    String? managerName,
    String? fleetId,
  }) async {
    try {
      final matricule = await _matriculeService.generateMatricule('Chauffeur');
      final docRef = _firestore.collection('users').doc();

      final user = UserModel(
        id: docRef.id,
        email: '',
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        role: 'Chauffeur',
        matricule: matricule,
        address: address,
        driverLicenseNumber: driverLicenseNumber,
        managerId: managerId,
        managerName: managerName,
        fleetId: fleetId,
        createdAt: DateTime.now(),
      );

      await docRef.set(user.toMap());
      return user;
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer tous les utilisateurs
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les utilisateurs actifs uniquement
  Future<List<UserModel>> getActiveUsers() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Rechercher des utilisateurs
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      if (query.isEmpty) {
        return getAllUsers();
      }

      final querySnapshot = await _firestore.collection('users').get();

      final normalizedQuery = query.toLowerCase();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .where((user) {
        final fullName = user.fullName.toLowerCase();
        final email = user.email.toLowerCase();
        final matricule = user.matricule?.toLowerCase() ?? '';
        final phone = user.phoneNumber?.toLowerCase() ?? '';

        return fullName.contains(normalizedQuery) ||
            email.contains(normalizedQuery) ||
            matricule.contains(normalizedQuery) ||
            phone.contains(normalizedQuery);
      }).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer un utilisateur par ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return UserModel.fromMap(doc.data()!, doc.id);
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour un utilisateur
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).update(user.toMap());
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour des champs spécifiques
  Future<void> updateUserFields(String userId, Map<String, dynamic> fields) async {
    try {
      await _firestore.collection('users').doc(userId).update(fields);
    } catch (e) {
      rethrow;
    }
  }

  /// Activer un utilisateur
  Future<void> activateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': true,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Désactiver un utilisateur
  Future<void> deactivateUser(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isActive': false,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer un utilisateur (désactivation logique uniquement)
  Future<void> deleteUser(String userId) async {
    try {
      await deactivateUser(userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Compter le nombre total d'utilisateurs
  Future<int> getUserCount() async {
    try {
      final querySnapshot = await _firestore.collection('users').count().get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Compter le nombre d'utilisateurs actifs
  Future<int> getActiveUserCount() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('isActive', isEqualTo: true)
          .count()
          .get();
      return querySnapshot.count ?? 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Récupérer les utilisateurs par rôle
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: role)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Écouter les changements d'utilisateurs en temps réel
  Stream<List<UserModel>> watchAllUsers() {
    return _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Écouter un utilisateur spécifique
  Stream<UserModel?> watchUser(String userId) {
    return _firestore.collection('users').doc(userId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromMap(doc.data()!, doc.id);
    });
  }

  /// Vérifier si un email existe déjà
  Future<bool> emailExists(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      rethrow;
    }
  }

  /// Vérifier si un numéro de téléphone existe déjà
  Future<bool> phoneExists(String phone) async {
    try {
      final normalized = Validators.normalizePhone(phone);

      // Chercher par normalizedPhone
      var query = await _firestore
          .collection('users')
          .where('normalizedPhone', isEqualTo: normalized)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return true;

      // Fallback : chercher par phoneNumber avec les 3 formats
      final rawDigits = normalized.replaceAll('+224', '');
      final formats = [normalized, '00224$rawDigits', rawDigits];

      for (final format in formats) {
        query = await _firestore
            .collection('users')
            .where('phoneNumber', isEqualTo: format)
            .limit(1)
            .get();
        if (query.docs.isNotEmpty) return true;
      }

      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Obtenir les statistiques des utilisateurs par rôle
  Future<Map<String, int>> getUserStatsByRole() async {
    try {
      final querySnapshot = await _firestore.collection('users').get();
      final stats = <String, int>{};

      for (final doc in querySnapshot.docs) {
        final user = UserModel.fromMap(doc.data(), doc.id);
        final role = user.role ?? 'Autres';
        stats[role] = (stats[role] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour le rôle d'un utilisateur (génère nouveau matricule)
  Future<void> updateUserRole({
    required String userId,
    required String newRole,
    required String modifiedBy,
    String? reason,
  }) async {
    try {
      // 1. Récupérer l'utilisateur actuel
      final user = await getUserById(userId);
      if (user == null) throw Exception('Utilisateur introuvable');

      // 2. Générer nouveau matricule
      final newMatricule = await _matriculeService.generateMatricule(newRole);

      // 3. Récupérer le nom du modificateur
      final modifier = await getUserById(modifiedBy);
      final modifierName = modifier?.fullName ?? modifier?.email ?? 'Système';

      // 4. Transaction Firestore
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        transaction.update(userRef, {
          'role': newRole,
          'matricule': newMatricule,
          'lastPermissionUpdate': FieldValue.serverTimestamp(),
        });

        // Créer entrée d'historique
        final historyRef = userRef.collection('permissionHistory').doc();
        transaction.set(historyRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'modifiedBy': modifiedBy,
          'modifiedByName': modifierName,
          'changeType': 'roleChanged',
          'previousRole': user.role,
          'newRole': newRole,
          'reason': reason,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour les permissions d'un utilisateur
  Future<void> updateUserPermissions({
    required String userId,
    required List<String> permissions,
    required String modifiedBy,
    String? reason,
  }) async {
    try {
      // Récupérer le nom du modificateur
      final modifier = await getUserById(modifiedBy);
      final modifierName = modifier?.fullName ?? modifier?.email ?? 'Système';

      // Transaction pour garantir la cohérence
      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        transaction.update(userRef, {
          'permissions': permissions,
          'lastPermissionUpdate': FieldValue.serverTimestamp(),
        });

        // Créer entrée d'historique
        final historyRef = userRef.collection('permissionHistory').doc();
        transaction.set(historyRef, {
          'timestamp': FieldValue.serverTimestamp(),
          'modifiedBy': modifiedBy,
          'modifiedByName': modifierName,
          'changeType': 'permissionsModified',
          'addedPermissions': permissions,
          'reason': reason,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour rôle ET permissions simultanément
  Future<void> updateUserRoleAndPermissions({
    required String userId,
    required String newRole,
    required List<String> additionalPermissions,
    required String modifiedBy,
    String? reason,
  }) async {
    try {
      // 1. Récupérer l'utilisateur actuel
      final user = await getUserById(userId);
      if (user == null) throw Exception('Utilisateur introuvable');

      // 2. Générer nouveau matricule si rôle changé
      var newMatricule = user.matricule ?? '';
      if (user.role != newRole) {
        newMatricule = await _matriculeService.generateMatricule(newRole);
      }

      // 3. Récupérer le nom du modificateur
      final modifier = await getUserById(modifiedBy);
      final modifierName = modifier?.fullName ?? modifier?.email ?? 'Système';

      // 4. Transaction Firestore
      debugPrint('🔄 Début de la transaction pour userId: $userId');
      debugPrint('   Rôle actuel: ${user.role}, Nouveau rôle: $newRole');
      debugPrint('   Permissions: $additionalPermissions');
      debugPrint('   Modifié par: $modifiedBy ($modifierName)');

      await _firestore.runTransaction((transaction) async {
        final userRef = _firestore.collection('users').doc(userId);

        final updates = <String, dynamic>{
          'permissions': additionalPermissions,
          'lastPermissionUpdate': FieldValue.serverTimestamp(),
        };

        if (user.role != newRole) {
          updates['role'] = newRole;
          updates['matricule'] = newMatricule;
        }

        transaction.update(userRef, updates);

        // Créer entrée d'historique
        final historyRef = userRef.collection('permissionHistory').doc();
        final historyData = {
          'timestamp': FieldValue.serverTimestamp(),
          'modifiedBy': modifiedBy,
          'modifiedByName': modifierName,
          'changeType': user.role != newRole ? 'roleChanged' : 'permissionsModified',
          if (user.role != newRole) 'previousRole': user.role,
          if (user.role != newRole) 'newRole': newRole,
          'addedPermissions': additionalPermissions,
          'reason': reason,
        };

        debugPrint('📝 Création de l\'entrée d\'historique: $historyData');
        transaction.set(historyRef, historyData);
      });

      debugPrint('✅ Transaction réussie pour userId: $userId');
    } catch (e) {
      debugPrint('❌ Erreur dans la transaction: $e');
      rethrow;
    }
  }

  /// Récupérer l'historique des permissions d'un utilisateur
  Future<List<Map<String, dynamic>>> getUserPermissionHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      debugPrint('🔍 Récupération de l\'historique pour userId: $userId');

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('permissionHistory')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      debugPrint('📊 Nombre d\'entrées d\'historique trouvées: ${snapshot.docs.length}');

      final history = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        debugPrint('📝 Entrée: ${data['changeType']} à ${data['timestamp']}');
        return data;
      }).toList();

      return history;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'historique: $e');
      rethrow;
    }
  }

  /// Assigner un responsable à un utilisateur
  Future<void> assignManager({
    required String userId,
    required String managerId,
    required String managerName,
  }) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'managerId': managerId,
        'managerName': managerName,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Retirer le responsable d'un utilisateur
  Future<void> removeManager({required String userId}) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'managerId': null,
        'managerName': null,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Écouter les utilisateurs gérés par un responsable
  Stream<List<UserModel>> watchManagedUsers(String managerId) {
    return _firestore
        .collection('users')
        .where('managerId', isEqualTo: managerId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => UserModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Mettre à jour les informations de base d'un utilisateur (nom, téléphone, etc.)
  /// [photoUrl] : null = ne pas modifier, '' = supprimer, URL = définir
  Future<void> updateUserBasicInfo({
    required String userId,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? department,
    String? address,
    String? driverLicenseNumber,
    DateTime? dateOfBirth,
    String? photoUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (firstName != null) updates['firstName'] = firstName;
      if (lastName != null) updates['lastName'] = lastName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (department != null) updates['department'] = department;
      if (address != null) updates['address'] = address;
      if (driverLicenseNumber != null) updates['driverLicenseNumber'] = driverLicenseNumber;
      if (dateOfBirth != null) updates['dateOfBirth'] = dateOfBirth.toIso8601String();
      if (photoUrl != null) {
        updates['photoUrl'] =
            photoUrl.isEmpty ? FieldValue.delete() : photoUrl;
      }

      if (updates.isNotEmpty) {
        await _firestore.collection('users').doc(userId).update(updates);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mettre à jour l'email d'un utilisateur dans Firestore
  Future<void> updateUserEmail({
    required String userId,
    required String email,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .update({'email': email});
  }
}
