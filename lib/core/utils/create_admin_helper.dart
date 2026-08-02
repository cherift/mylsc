import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Utilitaire pour créer le premier utilisateur administrateur RH
/// À UTILISER UNE SEULE FOIS puis supprimer ce fichier ou commenter le code
class CreateAdminHelper {
  /// Créer un utilisateur admin RH
  ///
  /// IMPORTANT: Cette fonction doit être appelée une seule fois pour créer
  /// le premier administrateur. Après cela, les autres utilisateurs peuvent
  /// être créés via l'interface de gestion.
  ///
  /// Usage:
  /// ```dart
  /// await CreateAdminHelper.createFirstAdmin(
  ///   email: 'admin@fleet.gn',
  ///   password: 'VotreMotDePasse123!',
  ///   firstName: 'Admin',
  ///   lastName: 'LSC',
  /// );
  /// ```
  static Future<void> createFirstAdmin({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String phoneNumber = '+224 623 45 67 89',
  }) async {
    try {
      final auth = FirebaseAuth.instance;
      final firestore = FirebaseFirestore.instance;

      debugPrint('🔄 Création de l\'utilisateur admin...');

      // Créer l'utilisateur dans Firebase Auth
      final userCredential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la création de l\'utilisateur');
      }

      debugPrint('✅ Utilisateur créé dans Firebase Auth: ${userCredential.user!.uid}');

      // Créer le profil dans Firestore
      final userData = {
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phoneNumber': phoneNumber,
        'role': 'RH',
        'matricule': 'RH0001',
        'isActive': true,
        'createdAt': DateTime.now().toIso8601String(),
        'lastLoginAt': DateTime.now().toIso8601String(),
      };

      await firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      debugPrint('✅ Profil créé dans Firestore');

      // Initialiser le compteur de matricules RH
      await firestore.collection('counters').doc('matricule_RH').set({
        'value': 1,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Compteur de matricules initialisé');

      debugPrint('');
      debugPrint('🎉 SUCCÈS! Utilisateur admin créé avec succès!');
      debugPrint('');
      debugPrint('📧 Email: $email');
      debugPrint('🔑 Mot de passe: $password');
      debugPrint('👤 Nom complet: $firstName $lastName');
      debugPrint('🎫 Matricule: RH0001');
      debugPrint('🎭 Rôle: RH (Ressources Humaines)');
      debugPrint('');
      debugPrint('⚠️  IMPORTANT: Changez le mot de passe après la première connexion!');
      debugPrint('⚠️  Vous pouvez maintenant vous connecter et créer d\'autres utilisateurs.');
      debugPrint('');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'admin: $e');
      rethrow;
    }
  }

  /// Vérifier si un admin existe déjà
  static Future<bool> adminExists() async {
    try {
      final firestore = FirebaseFirestore.instance;
      final adminQuery = await firestore
          .collection('users')
          .where('role', isEqualTo: 'RH')
          .limit(1)
          .get();

      return adminQuery.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Erreur lors de la vérification de l\'existence d\'un admin: $e');
      return false;
    }
  }
}
