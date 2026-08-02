import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/user_model.dart';

/// Repository pour gérer l'authentification Firebase
class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  /// Stream de l'utilisateur actuel
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  /// Utilisateur actuellement connecté
  User? get currentUser => _firebaseAuth.currentUser;

  /// Connexion avec email et mot de passe
  Future<UserModel> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de la connexion');
      }

      // Récupérer le profil utilisateur depuis Firestore
      try {
        final userProfile = await getUserProfile(userCredential.user!.uid);

        // Si le profil existe dans Firestore, mettre à jour la dernière connexion et le retourner
        if (userProfile != null) {
          await _updateLastLogin(userCredential.user!.uid);
          return userProfile;
        }

        // Si le profil n'existe pas, retourner une erreur
        throw Exception(
            'Profil utilisateur introuvable. Veuillez vous inscrire d\'abord.');
      } catch (firestoreError) {
        // Si Firestore échoue, propager l'erreur avec un message clair
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Inscription avec email et mot de passe
  Future<UserModel> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? firstName,
    String? lastName,
  }) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) {
        throw Exception('Échec de l\'inscription');
      }

      // NE PLUS utiliser displayName - stocker uniquement dans Firestore
      // Les données firstName et lastName sont stockées dans Firestore uniquement

      // Créer le profil utilisateur dans Firestore
      final user = UserModel(
        id: userCredential.user!.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        photoUrl: userCredential.user!.photoURL,
        createdAt: userCredential.user!.metadata.creationTime ?? DateTime.now(),
        lastLoginAt: userCredential.user!.metadata.lastSignInTime,
      );
      await _createUserProfile(user);

      return user;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Déconnexion
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  /// Réinitialisation du mot de passe
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  /// Trouver l'email associé à un numéro de téléphone
  ///
  /// Cette recherche s'exécute avant authentification : elle ne doit donc
  /// jamais interroger la collection `users` (qui exposerait tous les
  /// profils en lecture publique). `phone_lookup/{normalizedPhone}` ne
  /// contient qu'un email, indexé par un id que l'appelant connaît déjà.
  Future<String> findEmailByPhone(String phone) async {
    try {
      final normalized = Validators.normalizePhone(phone);

      final doc = await _firestore.collection('phone_lookup').doc(normalized).get();

      if (doc.exists && doc.data() != null) {
        final email = doc.data()!['email'] as String?;
        if (email != null && email.isNotEmpty) return email;
      }

      throw Exception('Aucun compte associé à ce numéro de téléphone');
    } on FormatException {
      throw Exception('Format de numéro de téléphone invalide');
    }
  }

  /// Créer le profil utilisateur dans Firestore
  Future<void> _createUserProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.id).set(user.toMap());
  }

  /// Mettre à jour la dernière connexion
  Future<void> _updateLastLogin(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastLoginAt': DateTime.now().toIso8601String(),
    });
  }

  /// Gérer les exceptions Firebase Auth
  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('Aucun utilisateur trouvé avec cet email');
      case 'wrong-password':
        return Exception('Mot de passe incorrect');
      case 'email-already-in-use':
        return Exception('Cet email est déjà utilisé');
      case 'invalid-email':
        return Exception('Email invalide');
      case 'weak-password':
        return Exception('Le mot de passe est trop faible');
      case 'user-disabled':
        return Exception('Ce compte a été désactivé');
      case 'too-many-requests':
        return Exception('Trop de tentatives. Réessayez plus tard');
      case 'operation-not-allowed':
        return Exception('Opération non autorisée');
      case 'invalid-credential':
        return Exception('Identifiants invalides');
      default:
        return Exception('Une erreur s\'est produite: ${e.message}');
    }
  }

  /// Récupérer le profil utilisateur depuis Firestore
  Future<UserModel?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, userId);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
